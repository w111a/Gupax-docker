# Plan: Tor Node Support for Gupax-docker

## Goal

Enable optional Tor support for the Monero node (monerod) in the Gupax container, allowing:
- Anonymous blockchain sync via Tor SOCKS5 proxy
- Transaction broadcasting to `.onion` peers only (`--tx-proxy`)
- Optional inbound hidden service for accepting Tor peer connections
- (Future) P2Pool/XMRig mining may optionally route through Tor — with latency caveats

## Phased Approach

### Phase 0: Investigation (No Dockerfile changes)

**Goal:** Understand the configuration layer before writing any code.

#### 0.1 - Where does Gupax store monerod config?

Gupax runs monerod as a subprocess. We need to answer:
- What command-line arguments does Gupax pass to monerod?
- Does Gupax write a `monerod.conf` file, or only use command-line args?
- Can we inject `--proxy` / `--tx-proxy` via config file without modifying Gupax source?
- Where is monerod state stored in the container (`/home/miner/.local/share/gupax/node/`?)

**Experiment:**
1. Build current container locally
2. Start it, let Gupax launch monerod from the GUI
3. In a separate shell: `docker exec gupax ps aux | grep monerod` — capture exact command line
4. Check `~/.local/share/gupax/` for any `monerod.conf` or `.conf` files
5. Check if Gupax writes state to `~/.local/share/gupax/state.toml` that includes node settings
6. Check if there's a `--data-dir` or `--config-file` argument we can observe

**Deliverable:** Document the exact mechanism Gupax uses to configure monerod.

#### 0.2 - Test Tor package in container

**Experiment:**
1. In the running container: `apt-get install -y tor`
2. Start tor: `tor --SocksPort 127.0.0.1:9050 --ControlPort 127.0.0.1:9051`
3. Verify: `curl --socks5 127.0.0.1:9050 https://check.torproject.org/api/ip`
4. Stop Gupax, restart with `--proxy 127.0.0.1:9050` manually added to monerod
5. Observe: does monerod connect to onion peers? Check logs.

**Deliverable:** Confirm Tor works inside the container and monerod can use it.

#### 0.3 - Test sidecar approach

**Experiment:**
1. In compose override, add a `tor` service:
   ```yaml
   tor:
     image: dperson/torproxy
     container_name: tor
     ports:
       - "9050:9050"
     networks:
       - gupax-net
   ```
2. Change Gupax container to connect via `tor:9050` instead of `127.0.0.1:9050`
3. Test monerod with `--proxy tor:9050`

**Deliverable:** Compare sidecar vs in-container Tor approach.

### Phase 1: Basic Tor Integration (In-container)

**Goal:** Add a working Tor daemon to the Gupax image with on/off toggle.

#### 1.1 - Dockerfile changes

- Add `tor` package to apt-get install list (~30-40MB)
- Optional: add `nyx` (Tor monitor) for debugging
- Copy a minimal `torrc` template into the image

#### 1.2 - start.sh changes

- Add `TOR_ENABLED` env var (default: `false`)
- If true, before starting Gupax:
  1. Validate `tor` binary exists
  2. Start `tor --SocksPort 127.0.0.1:9050` with minimal config
  3. Poll until Tor proves SOCKS5 works (`curl --socks5 127.0.0.1:9050 ...`)
  4. Only then start Gupax (so monerod can find Tor ready)
  
- If false, Tor doesn't start, no change to behavior

#### 1.3 - Config generation (TBD based on Phase 0 findings)

Based on 0.1, we need EITHER:
- **If Gupax reads monerod.conf:** Generate a config file with Tor settings and mount it
- **If Gupax uses CLI only (likely):** We may need to modify Gupax source to add `--proxy` / `--tx-proxy` args
- **If Gupax stores node config in state.toml:** We might be able to inject settings there

**Fallback:** If Gupax source modification is needed, document that the Docker feature is blocked pending an upstream change to `gupax-io/gupax`.

### Phase 2: Hidden Service (Optional Future)

**Goal:** Allow incoming Tor peer connections to monerod.

- Generate a Tor hidden service automatically:
  ```
  HiddenServiceDir /var/lib/tor/monero-node/
  HiddenServicePort 18084 127.0.0.1:18083
  ```
- Read the `.onion` hostname and display it or log it for the user
- Pass `--anonymous-inbound onion,<hostname>:18084` to monerod
- Mount `HiddenServiceDir` to a named volume for persistence across restarts

### Phase 3: Sidecar Architecture (Optional Future)

**Goal:** Extract Tor to a separate Docker container for shareability and isolation.

- Create a second `docker-compose.yml` or compose override with `tor` service
- Gupax image stays Tor-free (no size increase)
- Shared Docker networking or `--network=host` for Tor access
- `TOR_HOST=tor` env var to configure proxy endpoint

### Phase 4: P2Pool Over Tor (Caution)

**Goal:** If users explicitly opt in, allow P2Pool to route through Tor.

**WARNINGS to present:**
- Gupax maintainer's concern: latency-heavy circuits stale shares
- Should be disabled by default
- Could be a per-pool toggle in compose env vars

Implementation:
- Set `P2POOL_TOR=disabled|optional|forced` to cover user choice
- Read P2Pool CLI args from Gupax `state.toml` or modify manually

## Decision Tree

```
Phase 0.1: Where does Gupax configure monerod?
│
├─ Conf file readable? → Phase 1 with auto-generated config
├─ CLI only, but modifiable somewhere? → Check state.toml or mount a wrapper
└─ Hardcoded, no escape? → Needs upstream Gupax PR → Document as blocked
```

## Risk & Unknowns

| Risk | Mitigation |
|------|-----------|
| Gupax doesn't expose monerod proxy settings | Investigate config files; if blocked, open a Gupax upstream FR |
| Tor adds ~30-40MB to image | Optional via `TOR_ENABLED=false`; sidecar avoids this |
| Tor startup delays slow container start | Poll for Tor readiness instead of blind sleep |
| Hidden service hostname lost on restart | Mount to named volume |
| `nyx` adds more size | Only include if debugging needed; exclude from final image |
| P2Pool over Tor = stale shares | Default to disabled; gated behind explicit opt-in |

## Files to Create/Modify

| File | Action | Branch |
|------|--------|--------|
| `torrc` | New minimal Tor config template | feat/tor-node |
| `Dockerfile` | Add `tor` package | feat/tor-node |
| `start.sh` | Add Tor startup + readiness check | feat/tor-node |
| `docker-compose.yml` | Add `TOR_ENABLED` env var | feat/tor-node |
| `.env.example` | Add `TOR_ENABLED`, `TOR_HOST` | feat/tor-node |

## First Step

Launch the current container and inspect Gupax's monerod invocation.

# Plan: Gupax-docker Production Readiness

## Goal
Progress gupax-docker from "work in progress" to a stable, production-ready release that can be used with real Monero mining funds.

---

## Current Context

- **What works:** noVNC + Xvfb + x11vnc + websockify stack, Gupax download/verify/install in Dockerfile, auto-version detection via GitHub API, basic docker-compose setup
- **What is unknown:** actual runtime behavior of Gupax in this container, whether the wallet/node configuration flows work end-to-end, healthcheck readiness, resource limits
- **Key files:** `Dockerfile`, `start.sh`, `docker-compose.yml`, `.env.example`, `.github/workflows/docker-publish.yml`

---

## Proposed Approach

Phase the work into **4 stages**: Stability & Hardening → Security → Documentation & UX → Release.

---

## Step-by-Step Plan

### Phase 1: Stability & Hardening

#### 1.1 Add health checks
- Add `HEALTHCHECK` to Dockerfile for the noVNC port (6080)
- Add `HEALTHCHECK` to docker-compose.yml for the Gupax process
- Add a `docker-healthcheck.sh` script that verifies all services (Xvfb, x11vnc, websockify, gupax) are still running

#### 1.2 Resource limits
- Add `deploy.resources.limits` to docker-compose.yml (memory, CPU)
- Set reasonable defaults: 2GB memory, 2 CPUs
- Document these in the README

#### 1.3 Proper signal handling and graceful shutdown
- The current `start.sh` already has `trap cleanup SIGTERM SIGINT SIGQUIT` and kills processes
- Verify it works by running the container and sending SIGTERM
- Consider adding a `docker stop --time 30` grace period to allow Gupax to flush state

#### 1.4 Startup reliability
- Add retry logic around Xvfb/x11vnc/websockify startup in `start.sh` (1-2 retries with sleep)
- Add a startup probe / readiness check: wait until Gupax GUI is actually reachable before declaring the container healthy
- Consider adding a `GUPAX_STARTUP_TIMEOUT` env var (default 30s)

#### 1.5 Multi-arch support
- Currently builds only `linux/amd64`
- Add `linux/arm64` to `platforms` in `docker-publish.yml` (Raspberry Pi / ARM miners)
- Note: This requires QEMU setup in the workflow

#### 1.6 Persistent Monero wallet state
- Ensure the wallet file (`wallet.bin`) is stored in the `gupax-config` volume, not lost on restart
- Document this in the volumes section

---

### Phase 2: Security

#### 2.1 noVNC password protection
- Currently noVNC has **no password by default**
- Add `VNC_PASSWORD` env var → generate `passwdfile` for x11vnc `-rfbauth`
- Document that users should set this for any exposed deployment

#### 2.2 Read-only root filesystem
- Add `read-only: true` to docker-compose service (except for `/tmp` and volumes)
- This prevents arbitrary write access from compromised processes

#### 2.3 Non-root user enforcement
- Already running as `miner` user (good)
- Verify no binaries are `chmod 4777` or capabilities like `NET_ADMIN`

#### 2.4 Secrets management
- Currently `WALLET_ADDRESS` is passed as env var — this is visible in `docker ps`
- Consider supporting a `WALLET_SEED` or mounting the wallet from a secrets file instead
- At minimum, document that `WALLET_ADDRESS` should be considered semi-public

#### 2.5 Network isolation
- Add Docker network to compose
- Document firewall considerations for the exposed ports (3333, 18080, 18081, 18082)

---

### Phase 3: Documentation & UX

#### 3.1 Remove WIP warning once stable
- Once Phases 1 and 2 are complete and tested, remove the `[!WARNING]` block from README

#### 3.2 Update badges
- Add a "Version" badge showing current Gupax version
- Add a "Docker Image Size" badge (already there)
- Consider adding a "Downloads" badge

#### 3.3 Troubleshooting section expansion
- Add "Container exits immediately" debug section
- Add "Gupax GUI loads but mining doesn't start" section
- Add "How to check logs" (`docker compose logs -f gupax`)

#### 3.4 Unraid template update
- Memory notes indicate there's an Unraid template in `templates/` directory
- Verify it matches the current docker-compose config
- Add the noVNC WebUI port (6080) to the template

#### 3.5 CHANGELOG.md
- Review existing CHANGELOG.md, ensure it reflects current state
- Add v2.2.0 entry documenting the noVNC switch from the legacy P2Pool+XMRig approach

#### 3.6 Docker Hub / additional registries
- Currently only publishes to GHCR
- Consider also pushing to Docker Hub for easier discoverability

---

### Phase 4: Testing & Validation

#### 4.1 Smoke test
- On a fresh machine (or CI runner), run the full quick start:
  - `docker compose up -d`
  - `curl -s http://localhost:6080` → should return noVNC HTML
  - Wait 60s for Gupax to initialize
  - Verify Xvfb, x11vnc, websockify, gupax processes are all running inside container

#### 4.2 Wallet integration test
- Set a testnet Monero wallet address
- Verify Gupax shows the correct balance / mining stats
- This can be done in CI with a mock or testnet wallet

#### 4.3 Persistence test
- `docker compose down`
- `docker compose up -d`
- Verify config persists (wallet address retained, hashrate history intact)

#### 4.4 Upgrade test
- Start with current image, update compose to point to new image tag, `docker compose pull && up -d`
- Verify state survives across version upgrades

#### 4.5 CI smoke test
- Add a separate workflow (or step) that:
  - Spins up the container
  - Checks port 6080 responds
  - Checks Gupax process exists inside container (`docker exec gupax ps aux`)
  - Tears down cleanly

---

## Files Likely to Change

| File | Changes |
|------|---------|
| `Dockerfile` | HEALTHCHECK, multi-arch (QEMU), read-only rootFS |
| `start.sh` | Retry logic, readiness probe, startup timeout |
| `docker-compose.yml` | Resource limits, read-only, healthcheck, VNC password env |
| `.env.example` | Add `VNC_PASSWORD`, `GUPAX_STARTUP_TIMEOUT`, `SCREEN_RESOLUTION` |
| `README.md` | Remove WIP warning, expand troubleshooting, update badges |
| `.github/workflows/docker-publish.yml` | Multi-arch platforms |
| `templates/Unraid-template.xml` | Match current compose config, add 6080 WebUI port |
| `CHANGELOG.md` | Document v2.2.0 state |
| `docker-healthcheck.sh` (new) | Health check script for container |

---

## Risks & Tradeoffs

1. **Multi-arch builds** increase CI time (~2-3x) and QEMU emulation on ARM is slower than native — acceptable for a low-frequency workflow
2. **noVNC password** adds friction for local-only users — make it opt-in via env var with a clear default (no password for localhost)
3. **Health checks** may be tricky since Gupax is a GUI app — a simple port check on 6080 is the minimum viable health check
4. **ARM support** depends on whether upstream Gupax provides `linux-arm64` binaries — need to verify this before promising it

---

## Open Questions

1. Should this target **testnet** first before mainnet? (safer for users, easier to validate)
2. Is the current `GUPAX_VERSION` auto-detection via GitHub API reliable enough, or should it be a build arg?
3. Should there be a **tagged release** (`v2.2.0`, `v2.3.0`) separate from `latest`? 
4. Do you want to keep the legacy P2Pool+XMRig files as-is, or clean them up now that noVNC approach is the main path?
5. Any specific test environment available? (local machine, cloud VM, Unraid)

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
- **Current state:** `start.sh` has NO signal trap — background processes (Xvfb, x11vnc, websockify) are killed abruptly on `docker stop`
- Add `trap "kill 0" EXIT` to start.sh so all child processes receive SIGTERM on container shutdown
- Verify with `docker stop -t 30 gupax` — Gupax should have time to flush state
- Add `stop_grace_period: 30s` to compose if not already present (already present, confirmed)

#### 1.4 Startup reliability
- **Current state:** `start.sh` uses blind `sleep 2` / `sleep 1` to wait for Xvfb/x11vnc/websockify — processes may not actually be ready
- Replace with polling loops: use `xdpyinfo -display :1 >/dev/null 2>&1` to confirm Xvfb is truly up before proceeding
- Add retry logic (up to 10 attempts, 1s each) with descriptive error messages
- Add a `GUPAX_STARTUP_TIMEOUT` env var (default 30s)
- Add a startup probe / readiness check: wait until noVNC on port 6080 is reachable before declaring the container healthy

#### 1.5 Multi-arch support
- Currently builds only `linux/amd64`
- Add `linux/arm64` to `platforms` in `docker-publish.yml` (Raspberry Pi / ARM miners)
- Note: This requires QEMU setup in the workflow

#### 1.6 Persistent Monero wallet state
- Ensure the wallet file (`wallet.bin`) is stored in the `gupax-config` volume, not lost on restart
- Document this in the volumes section

#### 1.7 Tighten .dockerignore
- **Current state:** `.dockerignore` is missing: `.github/`, `templates/`, `start.sh`, `.env.example`
- `start.sh` is copied into the image at build time via `COPY start.sh` so it should NOT be in `.dockerignore` (that would break the build)
- Add `.github/` (workflows not needed in image), `templates/` (Unraid template not needed), `.env.example` (not needed in image), `*.md` (already there)
- Remove `!entrypoint.sh` from `.dockerignore` — that file doesn't exist and the negation is confusing

#### 1.8 Consider Alpine base image variant
- **Current state:** Uses `ubuntu:22.04` (~80MB overhead vs Alpine)
- Gupax + Xvfb + noVNC can run on Alpine, but NVIDIA GPU support may require Ubuntu
- Option A: Keep Ubuntu for broad compatibility
- Option B: Add `Dockerfile.alpine` variant targeting users who don't need NVIDIA
- Low priority — only if image size becomes a concern

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

#### 2.6 Remove unused gosu dependency
- **Current state:** `gosu` is installed in Dockerfile line 31 but never used — dead weight ~5MB
- Remove `gosu` from the apt-get install list
- If privilege escalation is ever needed, use `su` (already in Ubuntu) or add gosu back intentionally

#### 2.7 Add Docker security hardening to compose
- Add `security_opt: no-new-privileges:true` to the compose service
- Add `cap_drop: [ALL]` to drop all Linux capabilities
- Add `tmpfs: /tmp:noexec,nosuid,size=64m` for temp file protection
- These can be added alongside the existing Unraid template resource limits

#### 2.8 Fix CI workflow verbosity
- **Current state:** `docker-hub-push.yml` uses `--quiet` on `docker push` (lines 60, 62, 67), hiding failures in CI logs
- Remove `--quiet` flag from all `docker push` commands in the workflow so CI failures are visible

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
| `Dockerfile` | HEALTHCHECK, multi-arch (QEMU), read-only rootFS, remove gosu |
| `start.sh` | Signal trap, retry/polling loops, readiness probe, startup timeout |
| `docker-compose.yml` | Resource limits, read-only, healthcheck, VNC password env, cap_drop, security_opt, tmpfs |
| `.env.example` | Add `VNC_PASSWORD`, `GUPAX_STARTUP_TIMEOUT`, `SCREEN_RESOLUTION` |
| `.dockerignore` | Remove `!entrypoint.sh`, add `.github/`, `templates/`, `.env.example` |
| `README.md` | Remove WIP warning, expand troubleshooting, update badges |
| `.github/workflows/docker-publish.yml` | Multi-arch platforms |
| `.github/workflows/docker-hub-push.yml` | Remove `--quiet` from docker push |
| `templates/gupax-docker.xml` | Match current compose config, add 6080 WebUI port |
| `CHANGELOG.md` | Document v2.2.0 state |
| `docker-healthcheck.sh` (new) | Health check script for container |

---

## Risks & Tradeoffs

1. **Multi-arch builds** increase CI time (~2-3x) and QEMU emulation on ARM is slower than native — acceptable for a low-frequency workflow
2. **noVNC password** adds friction for local-only users — make it opt-in via env var with a clear default (no password for localhost)
3. **Health checks** may be tricky since Gupax is a GUI app — a simple port check on 6080 is the minimum viable health check
4. **ARM support** depends on whether upstream Gupax provides `linux-arm64` binaries — need to verify this before promising it
5. ** gosu removal** — if `gosu` was intended for future use (e.g., privilege escalation in start.sh), removing it now means re-adding later; document the decision
6. **Read-only rootfs** — adding `read_only: true` may break Gupax if it writes anywhere outside `/tmp`, `/home/miner/.local/state/gupax`, or the defined volumes; must test thoroughly
7. **cap_drop: ALL** — drops all capabilities including `NET_BIND_SERVICE` which Gupax may need for mining ports; test with actual mining workload

---

## Open Questions

1. Should this target **testnet** first before mainnet? (safer for users, easier to validate)
2. Is the current `GUPAX_VERSION` auto-detection via GitHub API reliable enough, or should it be a build arg?
3. Should there be a **tagged release** (`v2.2.0`, `v2.3.0`) separate from `latest`? 
4. Do you want to keep the legacy P2Pool+XMRig files as-is, or clean them up now that noVNC approach is the main path?
5. Any specific test environment available? (local machine, cloud VM, Unraid)

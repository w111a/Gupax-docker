# ✅ Gupax-docker — Project Roadmap & TODO

A prioritized checklist of everything that needs to be accomplished for **Gupax-docker** to be fully functional and production-ready.

---

## 🔴 Critical — App Won't Run Without These

- [x] **Working Dockerfile** — Multi-stage build that downloads and installs Gupax (or P2Pool + XMRig binaries) into a minimal runtime image
- [x] **Entrypoint script (`entrypoint.sh`)** — Starts P2Pool daemon, then XMRig, with proper signal handling and graceful shutdown
- [x] **Wallet address configuration** — Accept `WALLET_ADDRESS` as a required environment variable; fail fast if missing
- [x] **P2Pool startup** — P2Pool connects to the Monero network (either via an embedded monerod or an external node) and opens the local stratum port
- [x] **XMRig connects to P2Pool** — XMRig mines to `localhost:P2POOL_PORT` instead of a centralized pool
- [x] **Port exposure** — Publish P2Pool stratum port (default `3333`) and P2Pool p2p port (default `18080`)
- [x] **Data persistence** — Mount a volume for P2Pool data (`/root/.p2pool` or `/root/.gupax`) so the node doesn't resync from scratch on restart
- [x] **docker-compose.yml** — A working compose file with correct service definition, environment variables, ports, and volumes

---

## 🟡 Important — Needed for Real-World Usability

- [ ] **Monerod connectivity** — Support for connecting to an external monerod RPC node (host/port via env vars) or running monerod as a sidecar container
- [ ] **Optional sidecar monerod** — Add a `monerod` service in docker-compose.yml so users can run their own node alongside P2Pool
- [x] **Automatic restart policies** — `restart: unless-stopped` in compose; healthcheck-based restart for the P2Pool process
- [x] **Health checks** — Docker `HEALTHCHECK` instruction that verifies P2Pool is responding and XMRig is connected
- [x] **Thread count configuration** — `XMRIG_THREADS` env var to control CPU usage
- [ ] **P2Pool payout monitoring** — Log or surface P2Pool share/payout information
- [x] **Log management** — Configurable log levels; pipe logs to stdout/stderr for Docker log drivers
- [x] **`.dockerignore`** — Exclude unnecessary files from the build context (`.git`, `*.md`, etc.)
- [x] **`.env.example`** — Template environment file showing all available variables with sensible defaults
- [x] **Graceful shutdown** — Entrypoint traps `SIGTERM`/`SIGINT` and cleanly stops XMRig and P2Pool before exiting

---

## 🟢 Nice to Have — Polish & Production Hardening

- [ ] **Multi-arch builds** — Build for `linux/amd64` and `linux/arm64` (Raspberry Pi miners!)
- [ ] **GitHub Actions CI/CD** — Automated build, test, and push to `ghcr.io/w111a/gupax-docker` on tag/release
- [ ] **Image tagging strategy** — Tag images with Gupax/P2Pool/XMRig version numbers (e.g., `v1.4.2-p2pool-v3.6-xmrig-v6.21.0`)
- [x] **Non-root user** — Run the container as an unprivileged user for security (miner user)
- [ ] **Read-only root filesystem** — Mark the image as `read_only: true` where possible, writing only to volumes
- [x] **Resource limits in compose** — Set `mem_limit`, `cpus`, and `security_opt` in docker-compose.yml (6g memory)
- [x] **Pre-built binary caching** — Cache downloaded Gupax/P2Pool/XMRig tarballs in a build stage to speed up rebuilds (N/A - now uses direct download)
- [x] **Version pinning** — Pin exact versions of Gupax, P2Pool, and XMRig in the Dockerfile with SHA256 checksum verification
- [ ] **Monitoring integration** — Optional Prometheus metrics endpoint or sidecar exporter for P2Pool/XMRig stats
- [ ] **Docker Compose profiles** — Allow users to opt-in to the `monerod` sidecar with `--profile node`
- [ ] **GPU mining support** — Pass through GPU devices for XMRig CUDA/OpenCL mining
- [x] **Comprehensive README.md** — Professional documentation with Quick Start, configuration, ports, disclaimers, and links

---

## 📝 Documentation & Community

- [x] **README.md** with Quick Start (`docker run` + `docker-compose` examples)
- [x] **Configuration reference** table for all environment variables
- [ ] **Troubleshooting guide** — Common issues (port conflicts, wallet errors, P2Pool sync times)
- [ ] **CONTRIBUTING.md** — How to submit PRs, report issues, build locally
- [ ] **CHANGELOG.md** — Track changes per release
- [ ] **GitHub Issues templates** — Bug report and feature request templates
- [ ] **GitHub Releases** — Tagged releases with release notes and image digests

---

## 🧪 Testing & Validation

- [ ] **Smoke test** — Verify container starts, P2Pool connects, and XMRig begins mining with a test wallet
- [ ] **Restart test** — Verify data persists and P2Pool doesn't full-resync after `docker compose restart`
- [ ] **Missing wallet test** — Verify container exits with a clear error when `WALLET_ADDRESS` is not set
- [ ] **Port conflict test** — Verify meaningful error when ports `3333` or `18080` are already in use
- [ ] **Resource limit test** — Verify container respects `XMRIG_THREADS` and doesn't consume all CPU
- [x] **Graceful shutdown test** — `docker stop` cleanly terminates processes without data corruption (signal handling implemented)

---

## 🏗️ Suggested Architecture

```
┌──────────────────────────────────────────────┐
│              Gupax-docker Container           │
│                                               │
│  ┌───────────┐    ┌──────────────────────┐    │
│  │  P2Pool    │◄───│  Monerod (external    │    │
│  │  (daemon)  │    │  or sidecar)         │    │
│  └─────┬─────┘    └──────────────────────┘    │
│        │ stratum :3333                         │
│  ┌─────▼─────┐                                │
│  │  XMRig    │  ──► hashes → Monero network    │
│  │  (miner)  │                                │
│  └───────────┘                                │
│                                               │
│  Volume: /root/.gupax  (persistent data)      │
│  Entrypoint: entrypoint.sh (orchestrates all) │
└──────────────────────────────────────────────┘
```

---

## 📌 Current Build Information

- **Build method:** Pre-built static binaries (P2Pool v4.14, XMRig v6.26.0)
- **Binary verification:** SHA256 checksums verified at build time
- **Build time:** ~2-3 minutes (vs ~20+ minutes from source)
- **Helper script:** `scripts/get-checksums.sh` for fetching checksums for new versions

---

> **Priority:** The 🔴 Critical items are complete. Next focus on 🟡 Important items (especially monerod sidecar) and 🟢 Nice to Have items that improve production readiness.

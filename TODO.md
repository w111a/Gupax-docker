# ✅ Gupax-docker — Project Roadmap & TODO

---

## 🔴 Critical — App Won't Run Without These

- [x] **Working Dockerfile** — Gupax binary with Xvfb + x11vnc + noVNC
- [x] **noVNC web access** — Container accessible via browser at http://localhost:6080
- [x] **Wallet address configuration** — Accept `WALLET_ADDRESS` as a required env var
- [x] **docker-compose.yml** — Working compose with Gupax, noVNC, and volumes
- [x] **README.md** — Clear documentation with Quick Start and troubleshooting

---

## 🟡 Important — Real-World Usability

- [x] **Blockchain volume** — Mount existing Monero blockchain at `/home/miner/.bitmonero`
- [ ] **Multi-arch builds** — Support `linux/arm64` if Gupax provides arm64 binary
- [ ] **X11 troubleshooting docs** — Expand troubleshooting for common noVNC issues
- [ ] **CONTRIBUTING.md** — How to submit PRs and report issues
- [ ] **GitHub Releases** — Tagged releases with release notes

---

## 🟢 Nice to Have — Polish & Production Hardening

- [x] **Non-root user** — Runs as `miner` user for security
- [x] **Version pinning** — Gupax version pinned with SHA256 checksum verification
- [x] **Automatic restart** — `restart: unless-stopped` in compose
- [ ] **Read-only root filesystem** — Mark image as `read_only: true` where possible
- [ ] **Monitoring integration** — Optional Prometheus metrics if Gupax exposes them
- [ ] **VNC password** — Optional password protection for noVNC interface

---

## 📝 Documentation & Community

- [x] **README.md** — Quick Start, noVNC setup, configuration, troubleshooting
- [ ] **CHANGELOG.md** — Track changes per release (see v2.0.0 migration notes)
- [ ] **CONTRIBUTING.md** — How to submit PRs and report issues
- [ ] **GitHub Issues templates** — Bug report and feature request templates

---

## 🧪 Testing & Validation

- [ ] **Smoke test** — Verify container starts and noVNC is accessible at port 6080
- [ ] **Browser test** — Open http://localhost:6080, click Connect, verify Gupax appears
- [ ] **Blockchain test** — Mount existing blockchain, verify Gupax uses it
- [ ] **Restart test** — Verify Gupax config persists after `docker compose restart`
- [ ] **Version upgrade test** — Verify checksum mismatch fails the build

---

## 🏗️ Current Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Gupax-docker Container                      │
│                                                         │
│  ┌─────────────┐    ┌─────────────┐    ┌──────────┐   │
│  │    Xvfb     │◄───│   x11vnc    │◄───│  noVNC   │   │
│  │ (虚拟X服务器) │    │  (VNC服务)   │    │ (Web服务) │   │
│  └─────────────┘    └──────┬──────┘    └────┬─────┘   │
│         :1                  :1               :6080      │
│                             │                  │       │
│                    ┌────────▼─────────────────▼─────┐   │
│                    │         Gupax (egui GUI)    │   │
│                    │   runs on Xvfb display :1    │   │
│                    └──────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          │
                          │ TCP ports
                          ▼
              ┌───────────────────────────┐
              │   Host Browser Access      │
              │   http://localhost:6080    │
              └───────────────────────────┘
```

---

## 📌 Current Build Information

- **Build method:** Pre-built Gupax binary from upstream
- **Binary verification:** SHA256 checksum verified at build time
- **Gupax version:** v2.0.1
- **Image size:** ~375 MB
- **Components:** Gupax + Xvfb + x11vnc + websockify + noVNC

---

> **Note:** This container uses noVNC for browser-based GUI access. No X11 server needed on the host.

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [2.2.0] — 2026-04-18

### Added
- **Blockchain volume support** — Mount existing Monero blockchain at `/home/miner/.bitmonero`
- **Unraid template** — Updated with noVNC WebUI (`http://[IP]:[PORT:6080]`) and blockchain volume

### Changed
- **Unraid template** — Renamed from old P2Pool+XMRig direct approach to Gupax GUI approach

---

## [2.1.0] — 2026-04-18

### Added
- **noVNC self-contained GUI** — Container now accessible via web browser at http://localhost:6080
- **Xvfb + x11vnc + websockify** — Virtual framebuffer and VNC-to-WebSocket proxy
- **start.sh** — Startup script orchestrating Xvfb → x11vnc → websockify → Gupax

### Changed
- **Image size** reduced from ~6.14 GB to ~375 MB
- **DISPLAY requirement removed** — Container is now self-contained, no X11 on host needed

### Removed
- P2Pool and XMRig binaries (Gupax manages these internally)

---

## [2.0.0] — 2026-04-18

### Breaking Changes

**Complete rewrite. The previous version managed P2Pool and XMRig directly. This version packages the Gupax GUI application.**

- **Removed** direct P2Pool and XMRig binaries from the container
- **Removed** custom entrypoint script that orchestrated P2Pool + XMRig
- **Removed** environment variables: `P2POOL_MINI`, `XMRIG_THREADS`, `MONERO_NODE`, `P2POOL_STRATUM_PORT`, `P2POOL_MONERO_PORT`
- **Removed** volumes: `gupax-p2pool`, `gupax-monero`
- **Removed** Unraid template (old version)
- **Changed** container behavior: Now runs Gupax GUI application

### Added
- **Gupax GUI** — Full graphical interface for P2Pool + XMRig mining
- **X11 requirement** — Container fails if DISPLAY is not set
- **X11 socket mount** — `/tmp/.X11-unix` mounted automatically
- **Gupax config volume** — `gupax-config:/home/miner/.local/state/gupax`
- **CHANGELOG.md** — This file

### Legacy Files

These files are from the old P2Pool+XMRig direct approach and are kept for reference:
- `entrypoint.sh.LEGACY_P2POOL_XMRIG`
- `.env.example.LEGACY_P2POOL_XMRIG`
- `scripts/get-checksums.sh.LEGACY`
- `templates/gupax-docker.xml.LEGACY_P2POOL_XMRIG`

---

## [1.0.0] — Previous

See git history for previous changes.

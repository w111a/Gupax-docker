# Plan: Gupax with noVNC (Self-Contained Browser Access)

## Goal

Package Gupax as a **self-contained Docker container** accessible via web browser using noVNC. No X11 server needed on the host.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Gupax-docker Container                      │
│                                                         │
│  ┌─────────────┐    ┌─────────────┐    ┌──────────┐ │
│  │    Xvfb     │◄───│   x11vnc    │◄───│   noVNC  │ │
│  │ (虚拟X服务器) │    │  (VNC服务)   │    │ (Web服务) │ │
│  └─────────────┘    └──────┬──────┘    └────┬─────┘ │
│         :1                  :1               :6080    │
│                             │                  │       │
│                    ┌────────▼─────────────────▼─────┐ │
│                    │         Gupax (egui GUI)        │ │
│                    │   runs on Xvfb display :1       │ │
│                    └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                          │
                          │ TCP ports
                          ▼
              ┌───────────────────────────┐
              │   Host Browser Access     │
              │   http://localhost:6080   │
              └───────────────────────────┘
```

## Components Added

| Component | Package | Purpose |
|-----------|---------|---------|
| Xvfb | `xvfb` | Virtual framebuffer - fake X server |
| x11vnc | `x11vnc` | Shares Xvfb display as VNC server |
| noVNC | `websockify` | VNC-to-WebSocket proxy, serves HTML5 client |
| noVNC files | `novnc` | Web files for browser-based VNC client |

## Step-by-Step Plan

### Phase 1: Dockerfile Changes

1. **Add noVNC packages**
   ```dockerfile
   # Add to apt-get install line:
   xvfb
   x11vnc
   novnc
   websockify
   ```

2. **Create startup script** (`start.sh`)
   - Start Xvfb on display `:1`
   - Start x11vnc sharing `:1` on port 5900
   - Start websockify proxy (5900 → 6080)
   - Run Gupax with `DISPLAY=:1`
   - Handle graceful shutdown

3. **Set noVNC web root**
   - noVNC files installed to `/usr/share/novnc/`
   - Entrypoint serves these files via websockify

4. **Expose port 6080**
   - Change EXPOSE directive

### Phase 2: Entrypoint Script

5. **Create `start.sh`** (replaces entrypoint.sh)
   ```bash
   #!/bin/bash
   set -e

   # Start Xvfb on display :1
   Xvfb :1 -screen 0 1920x1080x24 &
   XVFB_PID=$!

   # Wait for Xvfb to start
   sleep 1

   # Start x11vnc
   x11vnc -display :1 -forever -shared -rfbport 5900 &
   X11VNC_PID=$!

   # Start websockify (noVNC proxy)
   websockify --web /usr/share/novnc 6080 localhost:5900 &
   WEBSOCKIFY_PID=$!

   # Run Gupax
   export DISPLAY=:1
   gosu miner gupax &!
   GUPAX_PID=$!

   # Cleanup function
   cleanup() {
     kill $GUPAX_PID $X11VNC_PID $WEBSOCKIFY_PID 2>/dev/null
     kill $XVFB_PID 2>/dev/null
   }
   trap cleanup SIGTERM SIGINT

   # Wait for any process to exit
   wait
   ```

### Phase 3: docker-compose.yml Changes

6. **Update for noVNC**
   ```yaml
   environment:
     - WALLET_ADDRESS=${WALLET_ADDRESS}
     # No DISPLAY needed - we provide our own Xvfb
   ports:
     - "6080:6080"   # noVNC web interface
     - "5900:5900"   # VNC (optional, for direct VNC access)
   ```

### Phase 4: .env.example Changes

7. **Remove DISPLAY requirement**
   ```bash
   # REMOVED: DISPLAY environment variable
   # ADDED: No longer needed - container is self-contained

   # Wallet still required
   WALLET_ADDRESS=
   ```

### Phase 5: README.md Updates

8. **Update documentation**
   - Remove all X11 setup instructions
   - New quick start: `docker compose up -d` then open `http://localhost:6080`
   - Explain noVNC connects automatically

## Files to Change

| File | Action |
|------|--------|
| `Dockerfile` | Add Xvfb, x11vnc, novnc, websockify |
| `start.sh` | Create new startup script |
| `docker-compose.yml` | Update ports, remove DISPLAY |
| `.env.example` | Remove DISPLAY variable |
| `README.md` | Rewrite for noVNC access |
| `entrypoint.sh.LEGACY_P2POOL_XMRIG` | Keep as-is |

## Files to Create

| File | Purpose |
|------|---------|
| `start.sh` | Main startup script for Xvfb + x11vnc + websockify + Gupax |

## Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `WALLET_ADDRESS` | Yes | — | Monero wallet address |
| `GUPAX_VERSION` | No | v2.0.1 | Gupax version |
| `GUPAX_SHA256` | No | (checksum) | Gupax SHA256 |
| `VNC_PASSWORD` | No | (none) | Optional VNC password |

## Ports

| Port | Protocol | Service | Description |
|---|---|---|---|
| 6080 | HTTP/TCP | noVNC | Web interface (connect here) |
| 5900 | VNC | x11vnc | Direct VNC access (optional) |

## Validation Steps

1. **Build test**
   - `docker build` succeeds

2. **noVNC access test**
   ```bash
   docker compose up -d
   curl -s http://localhost:6080 | head -20
   # Should return noVNC HTML
   ```

3. **Browser access test**
   - Open `http://localhost:6080` in browser
   - Click "Connect" (no password)
   - Gupax GUI should appear

4. **Shutdown test**
   - `docker compose down`
   - All processes should exit cleanly

## Image Size Impact

| Component | Size |
|-----------|------|
| Existing (Gupax + X11 libs) | ~360 MB |
| Xvfb + x11vnc + websockify | ~10 MB |
| noVNC web files | ~5 MB |
| **Total** | ~375 MB |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Xvfb performance issues | Low | 1920x1080x24 is reasonable |
| WebSocket connectivity issues | Low | Test with curl first |
| Gupax renderer issues in Xvfb | Medium | Xvfb provides software rendering |

## Open Questions

None — implementation straightforward.

---

*Plan created: 2026-04-18 — noVNC self-contained Gupax container*

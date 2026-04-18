#!/bin/bash
# =============================================================================
# Gupax-docker Startup Script
# Starts Xvfb → x11vnc → websockify → Gupax
# =============================================================================

set -e

WALLET_ADDRESS="${WALLET_ADDRESS:-}"
if [ -z "$WALLET_ADDRESS" ]; then
    echo "[ERROR] WALLET_ADDRESS environment variable must be set"
    echo "Example: docker run -e WALLET_ADDRESS=4ABC... ... ghcr.io/w111a/gupax-docker"
    exit 1
fi

echo "============================================="
echo "  Gupax-docker — Starting noVNC + Gupax"
echo "============================================="
echo ""
echo "  Wallet: ${WALLET_ADDRESS:0:10}...${WALLET_ADDRESS: -6}"
echo "  noVNC:  http://localhost:6080"
echo "  VNC:    localhost:5900"
echo ""
echo "============================================="

# Display number for Xvfb
DISPLAY_NUM=:1
SCREEN_RESOLUTION=${SCREEN_RESOLUTION:-1920x1080x24}

# Start Xvfb (virtual framebuffer)
echo "[*] Starting Xvfb on $DISPLAY_NUM..."
Xvfb $DISPLAY_NUM -screen 0 $SCREEN_RESOLUTION -nolisten tcp &
XVFB_PID=$!

# Wait for Xvfb to start
sleep 2

# Verify Xvfb is running
if ! kill -0 $XVFB_PID 2>/dev/null; then
    echo "[ERROR] Xvfb failed to start"
    exit 1
fi
echo "[+] Xvfb started on $DISPLAY_NUM"

# Start x11vnc (VNC server sharing Xvfb)
echo "[*] Starting x11vnc on port 5900..."
x11vnc -display $DISPLAY_NUM -forever -shared -rfbport 5900 -nopw &
X11VNC_PID=$!

sleep 1

# Verify x11vnc is running
if ! kill -0 $X11VNC_PID 2>/dev/null; then
    echo "[ERROR] x11vnc failed to start"
    kill $XVFB_PID 2>/dev/null
    exit 1
fi
echo "[+] x11vnc started on port 5900"

# Start websockify (WebSocket proxy for noVNC)
echo "[*] Starting websockify on port 6080..."
websockify --web /usr/share/novnc 6080 localhost:5900 &
WEBSOCKIFY_PID=$!

sleep 1

# Verify websockify is running
if ! kill -0 $WEBSOCKIFY_PID 2>/dev/null; then
    echo "[ERROR] websockify failed to start"
    kill $X11VNC_PID $XVFB_PID 2>/dev/null
    exit 1
fi
echo "[+] websockify started on port 6080"
echo ""
echo "[*] noVNC web interface ready at http://localhost:6080"
echo "[*] Gupax GUI should appear automatically"
echo ""

# Set DISPLAY for Gupax
export DISPLAY=$DISPLAY_NUM

# Cleanup function
cleanup() {
    echo ""
    echo "[*] Shutting down..."
    echo "[*] Stopping Gupax..."
    kill $GUPAX_PID 2>/dev/null || true
    wait $GUPAX_PID 2>/dev/null || true
    echo "[*] Stopping websockify..."
    kill $WEBSOCKIFY_PID 2>/dev/null || true
    wait $WEBSOCKIFY_PID 2>/dev/null || true
    echo "[*] Stopping x11vnc..."
    kill $X11VNC_PID 2>/dev/null || true
    wait $X11VNC_PID 2>/dev/null || true
    echo "[*] Stopping Xvfb..."
    kill $XVFB_PID 2>/dev/null || true
    wait $XVFB_PID 2>/dev/null || true
    echo "[+] Shutdown complete"
}

# Register signal handlers
trap cleanup SIGTERM SIGINT SIGQUIT

# Start Gupax
echo "[*] Starting Gupax on $DISPLAY..."
gosu miner gupax &
GUPAX_PID=$!

echo "[+] Gupax started with PID $GUPAX_PID"

# Wait for any process to exit
echo "[*] All services running. Press Ctrl+C to stop."
echo ""
wait -n
EXIT_CODE=$?

echo ""
echo "[*] Main process exited (code: $EXIT_CODE)"
cleanup

exit $EXIT_CODE

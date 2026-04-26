#!/bin/bash
# =============================================================================
# Gupax-docker Startup Script
# Starts Xvfb → openbox → x11vnc → websockify → Gupax
# =============================================================================

set -e

# Cleanup function — stops all background processes gracefully
cleanup() {
    echo ""
    echo "[*] Shutting down..."
    echo "[*] Stopping Gupax..."
    kill $GUPAX_PID 2>/dev/null || true
    wait $GUPAX_PID 2>/dev/null || true
    echo "[*] Stopping xdg-desktop-portal..."
    kill $PORTAL_PID 2>/dev/null || true
    wait $PORTAL_PID 2>/dev/null || true
    echo "[*] Stopping D-Bus session..."
    kill $DBUS_SESSION_BUS_PID 2>/dev/null || true
    wait $DBUS_SESSION_BUS_PID 2>/dev/null || true
    echo "[*] Stopping websockify..."
    kill $WEBSOCKIFY_PID 2>/dev/null || true
    wait $WEBSOCKIFY_PID 2>/dev/null || true
    echo "[*] Stopping x11vnc..."
    kill $X11VNC_PID 2>/dev/null || true
    wait $X11VNC_PID 2>/dev/null || true
    echo "[*] Stopping openbox..."
    kill $OPENBOX_PID 2>/dev/null || true
    wait $OPENBOX_PID 2>/dev/null || true
    echo "[*] Stopping Xvfb..."
    kill $XVFB_PID 2>/dev/null || true
    wait $XVFB_PID 2>/dev/null || true
    echo "[+] Shutdown complete"
}

# Register signal handlers for graceful shutdown
trap cleanup SIGTERM SIGINT SIGQUIT

echo "============================================="
echo "  Gupax-docker — Starting noVNC + Gupax"
echo "============================================="
echo ""
echo "  noVNC:  http://localhost:6080"
echo "  VNC:    localhost:5900"
echo ""
echo "============================================="

# Fix volume permissions if Docker overlay created root-owned directories
echo "[*] Checking state directory permissions..."
OWNER=$(stat -c '%U' /home/miner/.local/share/gupax 2>/dev/null || echo "unknown")
if [ "$OWNER" != "miner" ]; then
    echo "[!] Volume owned by '$OWNER' (expected: miner). Attempting to fix..."
    if /usr/bin/setpriv --reuid=0 --regid=0 --init-groups /usr/bin/chown -R miner:miner /home/miner/.local/share/gupax /home/miner/.bitmonero 2>/dev/null; then
        echo "[+] Permissions fixed"
    else
        echo "[!] Could not fix permissions. If the app fails to save settings, set MONERO_DATA_PATH to a host directory with correct owner (UID 999)"
    fi
else
    echo "[+] Data directories owned by miner -- OK"
fi

# Display number for Xvfb
DISPLAY_NUM=:1
export DISPLAY=$DISPLAY_NUM
SCREEN_RESOLUTION=${SCREEN_RESOLUTION:-1920x1080x24}

# Clean up stale X11 lock files (Docker volumes may persist these)
rm -f /tmp/.X${DISPLAY_NUM#*:}-lock /tmp/.X11-unix/X${DISPLAY_NUM#*:} 2>/dev/null || true
rm -rf /tmp/.X11-unix 2>/dev/null || true

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

# Start openbox (window manager — required for XI2 keyboard focus routing)
echo "[*] Starting openbox..."
openbox &>/dev/null &
OPENBOX_PID=$!
sleep 0.5
if ! kill -0 $OPENBOX_PID 2>/dev/null; then
    echo "[!] openbox failed, retrying..."
    sleep 1
    openbox &>/dev/null &
    OPENBOX_PID=$!
fi
echo "[+] openbox started (PID $OPENBOX_PID)"
sleep 1

# Start x11vnc (VNC server sharing Xvfb)
echo "[*] Starting x11vnc on port 5900..."
# VNC authentication — use VNC_PASSWORD if set, otherwise disable auth
if [ -n "$VNC_PASSWORD" ]; then
    VNC_FLAGS="-passwd $VNC_PASSWORD"
    echo "[*] VNC authentication: enabled (VNC_PASSWORD is set)"
else
    VNC_FLAGS="-nopw"
    echo "[*] VNC authentication: DISABLED (set VNC_PASSWORD to enable)"
fi
x11vnc -display $DISPLAY_NUM -forever -shared -rfbport 5900 $VNC_FLAGS &
X11VNC_PID=$!

sleep 1

# Verify x11vnc is running
if ! kill -0 $X11VNC_PID 2>/dev/null; then
    echo "[ERROR] x11vnc failed to start"
    kill $XVFB_PID 2>/dev/null
    exit 1
fi
echo "[+] x11vnc started on port 5900"

# Start noVNC
echo "[*] Starting noVNC on port 6080..."
websockify --web /usr/share/novnc 6080 localhost:5900 &
WEBSOCKIFY_PID=$!

sleep 1

# Verify websockify is running
if ! kill -0 $WEBSOCKIFY_PID 2>/dev/null; then
    echo "[ERROR] websockify failed to start"
    kill $X11VNC_PID $XVFB_PID 2>/dev/null
    exit 1
fi
echo "[+] noVNC started on port 6080"
echo ""
echo "[*] noVNC web interface ready at http://localhost:6080"
echo "[*] Gupax GUI should appear automatically"
echo ""

# Start D-Bus session for file dialog support (zenity, xdg-desktop-portal, etc.)
echo "[*] Starting D-Bus session..."
eval $(dbus-launch --sh-syntax)
export DBUS_SESSION_BUS_ADDRESS
echo "[+] D-Bus session started"

# Start xdg-desktop-portal (file picker backend for GTK/zenity)
echo "[*] Starting xdg-desktop-portal..."
/usr/libexec/xdg-desktop-portal &
PORTAL_PID=$!
echo "[+] xdg-desktop-portal started (PID $PORTAL_PID)"

# Start Gupax — runs as child of this script so cleanup() can manage it
echo "[*] Starting Gupax..."
/usr/local/bin/gupax/gupax &
GUPAX_PID=$!
echo "[+] Gupax started (PID $GUPAX_PID)"

# Wait specifically for Gupax — other services dying should NOT kill the container.
echo "[*] All services running. Press Ctrl+C to stop."
echo ""
wait $GUPAX_PID
EXIT_CODE=$?

echo ""
echo "[*] Gupax exited (code: $EXIT_CODE)"
cleanup
exit $EXIT_CODE
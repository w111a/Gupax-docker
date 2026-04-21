#!/bin/bash
# =============================================================================
# Gupax-docker Startup Script
# Starts Xvfb → x11vnc → websockify → Gupax
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

# Display number for Xvfb
DISPLAY_NUM=:1
SCREEN_RESOLUTION=${SCREEN_RESOLUTION:-1920x1080x24}

# Remove stale X lock file and socket from previous runs
rm -f /tmp/.X${DISPLAY_NUM#*:}-lock /tmp/.X11-unix/X${DISPLAY_NUM#*:} 2>/dev/null

# Kill any stale Xvfb process still holding the display
for pid in $(pidof Xvfb 2>/dev/null); do
    kill -9 $pid 2>/dev/null && echo "[*] Killed stale Xvfb (PID $pid)" || true
done

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

# Configure keyboard layout for winit (Gupax's windowing library)
echo "[*] Configuring keyboard layout..."
setxkbmap us 2>/dev/null || echo "[!] setxkbmap failed (non-fatal)"

# Start x11vnc (VNC server sharing Xvfb)
echo "[*] Starting x11vnc on port 5900..."
x11vnc -display $DISPLAY_NUM -forever -shared -rfbport 5900 -nopw &
X11VNC_PID=$!

# Re-enable X autorepeat that x11vnc disables on client connect
xset r on 2>/dev/null || true

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
# Note: container already runs as 'miner' user (see USER directive in Dockerfile)
# No gosu/su needed — we are already miner.
echo "[*] Starting Gupax..."
/usr/local/bin/gupax/gupax &
GUPAX_PID=$!

# Wait for any process to exit — this is what keeps the container running.
# When Gupax exits, cleanup() runs and stops everything.
echo "[*] All services running. Press Ctrl+C to stop."
echo ""
wait -n
EXIT_CODE=$?

echo ""
echo "[*] Main process exited (code: $EXIT_CODE)"
cleanup
exit $EXIT_CODE

#!/bin/bash
# =============================================================================
# Gupax-docker Startup Script
# Starts Xvfb → x11vnc → websockify → Gupax
# =============================================================================

set -e

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

# Create index.html redirect so http://host:6080/ goes to the noVNC connect page
echo '[html][head][meta http-equiv="refresh" content="0;url=vnc.html"][/head][body][a href="vnc.html"]noVNC[/a][/body][/html]' \
    | sed 's/\[/</g; s/\]/>/g' > /usr/share/novnc/index.html

# Start noVNC web interface using the official launch.sh wrapper
echo "[*] Starting noVNC on port 6080..."
/usr/share/novnc/utils/launch.sh --vnc localhost:5900 --listen 6080 &
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

# Set DISPLAY for Gupax
export DISPLAY=$DISPLAY_NUM

# Start Gupax in the foreground — exec replaces this shell so Gupax
# becomes PID 1. When Gupax exits, the container stops gracefully and
# all background processes (Xvfb, x11vnc, websockify) receive SIGTERM.
echo "[*] Starting Gupax..."
exec /usr/local/bin/gupax/gupax


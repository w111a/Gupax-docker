#!/bin/bash
# =============================================================================
# Gupax-docker Startup Script
# Starts Xvfb → openbox → x11vnc → websockify → Gupax
# Optional Tor daemon for monerod-over-Tor (TOR_ENABLED=true)
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
    echo "[*] Stopping Tor..."
    kill $TOR_PID 2>/dev/null || true
    wait $TOR_PID 2>/dev/null || true
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
if [ "${TOR_ENABLED:-false}" = "true" ]; then
    echo "  Tor:    ENABLED (SOCKS5 127.0.0.1:9050)"
    echo "  Tip:    Set Node arguments to --p2p-bind-ip=127.0.0.1 --no-igd --proxy=127.0.0.1:9050"
else
    echo "  Tor:    disabled (set TOR_ENABLED=true to enable)"
fi
echo "============================================="

# Fix volume permissions — container starts as root, no setpriv needed
echo "[*] Fixing data directory permissions..."
chown -R miner:miner /home/miner/.local/share/gupax /home/miner/.bitmonero 2>/dev/null || true

# Pre-create Gupax binary subdirectories on the persistent volume and symlink
# them into /usr/local/bin/gupax/ so Gupax downloads binaries to the volume,
# not to the root-owned, non-persistent image layer.
for dir in p2pool node xmrig xmrig-proxy; do
    mkdir -p /home/miner/.local/share/gupax/$dir
    ln -sfn /home/miner/.local/share/gupax/$dir /usr/local/bin/gupax/$dir
done
chown -R miner:miner /home/miner/.local/share/gupax 2>/dev/null || true

# Safety net: Unraid FUSE filesystems don't support chown to arbitrary UIDs.
# Make directories traversable by everyone regardless of ownership.
chmod a+rx /home/miner /home/miner/.local /home/miner/.local/share 2>/dev/null || true
chmod -R a+rwX /home/miner/.local/share/gupax 2>/dev/null || true
chmod a+rwX /home/miner/.bitmonero 2>/dev/null || true

# Display number for Xvfb
DISPLAY_NUM=:1
SCREEN_RESOLUTION=${SCREEN_RESOLUTION:-1920x1080x24}

# ── Tor daemon (optional) ──────────────────────────────────────────────────
if [ "${TOR_ENABLED:-false}" = "true" ]; then
    echo "[*] Tor is enabled — starting Tor daemon..."

    # Prepare Tor directories with restrictive permissions (required for HS)
    mkdir -p /home/miner/.tor
    chown root:root /home/miner/.tor
    chmod 700 /home/miner/.tor

    # Generate minimal torrc: SOCKS5 outbound proxy + hidden service for monerod P2P
    cat > /home/miner/.tor/torrc <<'TORRC'
SocksPort 127.0.0.1:9050
DataDirectory /home/miner/.tor
PidFile /home/miner/.tor/tor.pid
HiddenServiceDir /home/miner/.tor/hs_monerod
HiddenServicePort 18080 127.0.0.1:18084
TORRC
    chmod 600 /home/miner/.tor/torrc

    /usr/sbin/tor --torrc-file /home/miner/.tor/torrc &
    TOR_PID=$!

    echo "[*] Waiting for Tor SOCKS proxy (127.0.0.1:9050) to be ready..."
    for i in $(seq 1 30); do
        if nc -z 127.0.0.1 9050 2>/dev/null; then
            echo "[+] Tor SOCKS proxy is ready (127.0.0.1:9050)"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "[!] WARNING: Tor SOCKS proxy did not become ready within 30s — continuing anyway"
        else
            sleep 1
        fi
    done

    # ── Hidden Service .onion address ───────────────────────────────────────
    echo "[*] Waiting for hidden service .onion address..."
    HS_HOSTNAME=""
    for i in $(seq 1 30); do
        if [ -f /home/miner/.tor/hs_monerod/hostname ]; then
            HS_HOSTNAME=$(tr -d '[:space:]' < /home/miner/.tor/hs_monerod/hostname 2>/dev/null)
            if [ -n "$HS_HOSTNAME" ]; then
                break
            fi
        fi
        if [ $i -eq 30 ]; then
            echo "[!] WARNING: Hidden service .onion address not generated in time"
        else
            sleep 1
        fi
    done

    if [ -n "$HS_HOSTNAME" ]; then
        echo "[+] Monero node hidden service: ${HS_HOSTNAME}"
        HS_KEY="${HS_HOSTNAME}"
        echo "[+] Recommended monerod arguments (Gupax → Node → Arguments):"
        echo "    --restricted-rpc"
        echo "    --p2p-bind-ip=127.0.0.1"
        echo "    --no-igd"
        echo "    --proxy=127.0.0.1:9050"
        echo "    --tx-proxy=tor,127.0.0.1:9050"
        echo "    --anonymous-inbound=${HS_KEY},127.0.0.1:18084,40"
        # Persist for reference across container restarts
        cat > /home/miner/.tor/monerod_onion.txt <<EOF
Monero Node .onion: ${HS_HOSTNAME}
Restricted RPC:     --restricted-rpc
P2P bind IP:       --p2p-bind-ip=127.0.0.1
No IGD:            --no-igd
Anonymous inbound: --anonymous-inbound=${HS_KEY},127.0.0.1:18084,40
Outbound proxy:    --proxy=127.0.0.1:9050
Tx proxy:          --tx-proxy=tor,127.0.0.1:9050
Set both in Gupax → Node tab → Arguments
EOF
    fi
else
    TOR_PID=""
fi

# Remove stale X lock file and socket from previous runs
rm -f /tmp/.X${DISPLAY_NUM#*:}-lock /tmp/.X11-unix/X${DISPLAY_NUM#*:} 2>/dev/null
rm -rf /tmp/.X11-unix 2>/dev/null || true

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

# Configure keyboard layout for winit (Gupax's windowing library)
echo "[*] Configuring keyboard layout..."
setxkbmap us 2>/dev/null || echo "[!] setxkbmap failed (non-fatal)"

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
x11vnc -display $DISPLAY_NUM -forever -shared -rfbport 5900 $VNC_FLAGS -noxfixes -cursor arrow &
X11VNC_PID=$!

# Re-enable X autorepeat that x11vnc disables on client connect (run 3x as x11vnc recommends)
xset r on 2>/dev/null || true
sleep 0.5
xset r on 2>/dev/null || true
sleep 0.5
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

# Re-enable X autorepeat after noVNC connects (x11vnc disables it on client connect)
sleep 2
xset r on 2>/dev/null || true

# Debug: show X keyboard state
echo "[D] Keyboard repeat setting:"
xset q 2>/dev/null | grep -A2 "Keyboard" || echo "[D] xset q failed"

echo "[D] X input devices:"
xinput list 2>/dev/null || echo "[D] xinput failed"

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

# Detect the user to run Gupax as, matching the data volume owner.
# Auto-detected from volume owner; override with PUID/PGID env vars.
# On Unraid/FUSE shares where chown fails, set PUID=99 PGID=100.
PUID=${PUID:-$(stat -c '%u' /home/miner/.local/share/gupax 2>/dev/null || echo "0")}
PGID=${PGID:-$(stat -c '%g' /home/miner/.local/share/gupax 2>/dev/null || echo "0")}

if command -v gosu >/dev/null 2>&1 && gosu "$PUID:$PGID" true 2>/dev/null; then
    echo "[*] Running Gupax as UID:$PUID GID:$PGID"
    gosu "$PUID:$PGID" env HOME=/home/miner /usr/local/bin/gupax/gupax &
    GUPAX_PID=$!
else
    echo "[*] gosu unavailable — running as current user (rootless Docker?)"
    HOME=/home/miner /usr/local/bin/gupax/gupax &
    GUPAX_PID=$!
fi
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

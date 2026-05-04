# =============================================================================
# Gupax-docker — Dockerfile
# Gupax GUI for P2Pool + XMRig Monero mining
# Self-contained with noVNC — access via web browser at http://localhost:6080
#
# Standalone approach — only Gupax GUI is bundled.
# P2Pool, XMRig, monerod, and xmrig-proxy are downloaded at runtime by Gupax
# and persisted in /home/miner/.local/share/gupax via the gupax-share volume.
# =============================================================================

FROM ubuntu:22.04

# Prevent interactive tzdata prompt from blocking the build
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Xvfb display for headless GUI
ENV DISPLAY=:1

# VNC password — set VNC_PASSWORD to require auth; leave empty for no auth
ENV VNC_PASSWORD=

# Install X11 (for Xvfb), VNC, noVNC, GUI file manager, and Gupax runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb \
    x11-xserver-utils \
    x11vnc \
    novnc \
    websockify \
    libgl1-mesa-glx \
    libgl1 \
    libasound2 \
    libpulse0 \
    ca-certificates \
    curl \
    libxkbcommon-x11-0 \
    python3 \
    zenity \
    tor \
    netcat-openbsd \
    gosu \
    openbox \
    dbus-x11 \
    dbus \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    x11-apps \
    xinput \
    sudo \
    && rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates \
    && groupadd -r miner \
    && useradd -r -g miner -m -d /home/miner miner

# Allow passwordless sudo for XMRig only — Gupax on Linux spawns XMRig via pkexec
# which is unavailable in Docker; we provide a pkexec→sudo wrapper instead.
# Path: where Gupax downloads XMRig at runtime (under gupax-share volume).
RUN echo "miner ALL=(ALL) NOPASSWD: /home/miner/.local/share/gupax/xmrig/xmrig" > /etc/sudoers.d/gupax-xmrig \
    && chmod 0440 /etc/sudoers.d/gupax-xmrig

# Provide a pkexec wrapper that delegates to sudo (no PolicyKit agent in container)
RUN printf '#!/bin/sh\nexec sudo "$@"\n' > /usr/local/bin/pkexec \
    && chmod +x /usr/local/bin/pkexec

# =============================================================================
# Install standalone Gupax (Gupax GUI only — binaries downloaded at runtime)
# Gupax downloads P2Pool, XMRig, monerod, and xmrig-proxy internally.
# Downloaded binaries are persisted in /home/miner/.local/share/gupax
# via a named volume (gupax-share) so they survive container restarts.
# =============================================================================

WORKDIR /tmp/install

# --- Gupax v2.0.1 (standalone tarball — no bundled binaries) ---
# SHA256: 67abf40f8c452f637a45644f3b80815cdc44f55e45bc3901d7f66179d65495d5
RUN echo "67abf40f8c452f637a45644f3b80815cdc44f55e45bc3901d7f66179d65495d5  gupax.tar.gz" > gupax.sha256 \
    && curl -fsSL "https://github.com/gupax-io/gupax/releases/download/v2.0.1/gupax-v2.0.1-linux-x64.tar.gz" -o gupax.tar.gz \
    && sha256sum --check gupax.sha256 \
    && tar -xzf gupax.tar.gz \
    && mkdir -p /usr/local/bin/gupax \
    && mv gupax-v2.0.1-linux-x64/gupax /usr/local/bin/gupax/gupax \
    && chmod +x /usr/local/bin/gupax/gupax \
    && ln -s /usr/local/bin/gupax/gupax /usr/local/bin/gupax-bin \
    && rm -rf gupax.tar.gz gupax.sha256 gupax-v2.0.1-linux-x64 /tmp/install

# Labels
LABEL maintainer="w111a" \
      description="Gupax — GUI for P2Pool + XMRig Monero mining in Docker (noVNC enabled, standalone binaries + optional Tor)" \
      org.opencontainers.image.source="https://github.com/w111a/Gupax-docker" \
      org.opencontainers.image.icon="https://raw.githubusercontent.com/gupax-io/gupax/main/assets/images/icons/icon.png" \
      org.opencontainers.image.version="v2.0.1-standalone-tor" \
      gupax.version="v2.0.1"


# Create index.html redirect at build time (avoids any runtime permission issues)
RUN echo '<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0;url=vnc.html"></head><body><a href="vnc.html">Click to connect</a></body></html>' > /usr/share/novnc/index.html

# Copy startup script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 6080 5900
EXPOSE 3333 37889 18080 18081 18082

# Pre-create .bitmonero directory with miner ownership + symlink
# This fixes monerod's relative path resolution when Gupax launches it
# from /usr/local/bin/gupax/node/ (its working directory).
RUN mkdir -p /home/miner/.bitmonero && chown miner:miner /home/miner/.bitmonero \
    && ln -sf /home/miner/.bitmonero /usr/local/bin/gupax/.bitmonero

# Container starts as root so start.sh can fix volume permissions.
# start.sh drops to the miner user via gosu before launching Gupax.
WORKDIR /home/miner

# Health check — verify noVNC web interface is responding
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:6080/')" || exit 1

ENTRYPOINT ["/usr/local/bin/start.sh"]

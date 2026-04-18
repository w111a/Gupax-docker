# =============================================================================
# Gupax-docker — Dockerfile
# Gupax GUI for P2Pool + XMRig Monero mining
# Self-contained with noVNC — access via web browser at http://localhost:6080
#
# Build args:
#   GUPAX_VERSION  — Gupax release tag (default: v2.0.1)
#   GUPAX_SHA256    — SHA256 checksum for Gupax binary (required for verification)
#
# Ports:
#   6080 — noVNC web interface (connect your browser here)
#   5900 — VNC server (optional, for direct VNC access)
# =============================================================================

FROM ubuntu:22.04

LABEL maintainer="w111a"
LABEL description="Gupax — GUI for P2Pool + XMRig Monero mining in Docker (noVNC enabled)"
LABEL org.opencontainers.image.source="https://github.com/w111a/Gupax-docker"

# Build arguments
ARG GUPAX_VERSION=v2.0.1
ARG GUPAX_SHA256=67abf40f8c452f637a45644f3b80815cdc44f55e45bc3901d7f66179d65495d5

# Gupax release URL
ENV GUPAX_URL="https://github.com/gupax-io/gupax/releases/download/${GUPAX_VERSION}/gupax-${GUPAX_VERSION}-linux-x64.tar.gz"

# Xvfb display for headless GUI
ENV DISPLAY=:1

# Install X11 (for Xvfb), VNC, noVNC, and Gupax runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # X11 for Xvfb (virtual framebuffer)
    xvfb \
    x11-xserver-utils \
    # VNC server
    x11vnc \
    # noVNC / WebSocket proxy
    novnc \
    websockify \
    # Gupax GUI dependencies (OpenGL/audio)
    libgl1-mesa-glx \
    libgl1 \
    libasound2 \
    libpulse0 \
    # Utilities
    ca-certificates \
    curl \
    gosu \
    && rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates \
    && groupadd -r miner \
    && useradd -r -g miner -m -d /home/miner miner

# Download, verify, and extract Gupax
WORKDIR /tmp/gupax
RUN set -eux; \
    curl -fsSL "$GUPAX_URL" -o gupax.tar.gz; \
    printf '%s  %s\n' "$GUPAX_SHA256" "gupax.tar.gz" | sha256sum --check --status; \
    tar -xzf gupax.tar.gz; \
    GUPATH=$(find . -name 'gupax' -type f); \
    mv "$GUPATH" /usr/local/bin/gupax; \
    chmod +x /usr/local/bin/gupax; \
    rm -rf /tmp/gupax

# Create Gupax state directory
RUN mkdir -p /home/miner/.local/state/gupax && chown -R miner:miner /home/miner

# Copy startup script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Ports exposed:
# 6080 — noVNC web interface (HTTP + WebSocket)
# 5900 — VNC server (for direct VNC clients)
EXPOSE 6080 5900

# Mining ports (for P2Pool/XMRig-proxy)
EXPOSE 3333 37889 18080 18081 18082

# Persistent Gupax state
VOLUME ["/home/miner/.local/state/gupax"]

USER miner
WORKDIR /home/miner

# Run the startup script which launches Xvfb + x11vnc + websockify + Gupax
ENTRYPOINT ["/usr/local/bin/start.sh"]

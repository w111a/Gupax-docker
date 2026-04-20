# =============================================================================
# Gupax-docker — Dockerfile
# Gupax GUI for P2Pool + XMRig Monero mining
# Self-contained with noVNC — access via web browser at http://localhost:6080
#
# Version auto-detected at build time via GitHub API — no build args needed
# =============================================================================

FROM ubuntu:22.04

# Prevent interactive tzdata prompt from blocking the build
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Xvfb display for headless GUI
ENV DISPLAY=:1

# Install X11 (for Xvfb), VNC, noVNC, and Gupax runtime dependencies
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
    && rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates \
    && groupadd -r miner \
    && useradd -r -g miner -m -d /home/miner miner

# =============================================================================
# Install bundled Gupax (Gupax + P2Pool + XMRig)
# Structure: /usr/local/bin/gupax/
#   gupax/          — Gupax v2.0.1 GUI
#   gupax/p2pool/   — P2Pool v4.14 binary + docs
#   gupax/xmrig/    — XMRig v6.26.0 binary + config
# Gupax finds binaries relative to its own executable location.
# =============================================================================

WORKDIR /tmp/install

# --- Gupax v2.0.1 ---
RUN echo "67abf40f8c452f637a45644f3b80815cdc44f55e45bc3901d7f66179d65495d5  gupax.tar.gz" > gupax.sha256 \
    && curl -fsSL "https://github.com/gupax-io/gupax/releases/download/v2.0.1/gupax-v2.0.1-linux-x64.tar.gz" -o gupax.tar.gz \
    && sha256sum --check gupax.sha256 \
    && tar -xzf gupax.tar.gz \
    && mkdir -p /usr/local/bin/gupax \
    && mv gupax-v2.0.1-linux-x64/gupax /usr/local/bin/gupax/gupax \
    && rm -rf gupax.tar.gz gupax.sha256 gupax-v2.0.1-linux-x64

# --- P2Pool v4.14 ---
# SHA256: e64f6f774dc35352b8ae4397ccdb92ce0cc935cdfb100eac58d44e49f8796a01
RUN echo "e64f6f774dc35352b8ae4397ccdb92ce0cc935cdfb100eac58d44e49f8796a01  p2pool.tar.gz" > p2pool.sha256 \
    && curl -fsSL "https://github.com/SChernykh/p2pool/releases/download/v4.14/p2pool-v4.14-linux-x64.tar.gz" -o p2pool.tar.gz \
    && sha256sum --check p2pool.sha256 \
    && tar -xzf p2pool.tar.gz \
    && mkdir -p /usr/local/bin/gupax/p2pool \
    && mv p2pool-v4.14-linux-x64/p2pool /usr/local/bin/gupax/p2pool/ \
    && mv p2pool-v4.14-linux-x64/README.md /usr/local/bin/gupax/p2pool/ \
    && mv p2pool-v4.14-linux-x64/LICENSE /usr/local/bin/gupax/p2pool/ \
    && rm -rf p2pool.tar.gz p2pool.sha256 p2pool-v4.14-linux-x64

# --- XMRig v6.26.0 (jammy build for Ubuntu 22.04) ---
# SHA256: ca82fc8426187880dffa502363849af6258e65fdb675a9cc9984a2b843854087
RUN echo "ca82fc8426187880dffa502363849af6258e65fdb675a9cc9984a2b843854087  xmrig.tar.gz" > xmrig.sha256 \
    && curl -fsSL "https://github.com/xmrig/xmrig/releases/download/v6.26.0/xmrig-6.26.0-jammy-x64.tar.gz" -o xmrig.tar.gz \
    && sha256sum --check xmrig.sha256 \
    && tar -xzf xmrig.tar.gz \
    && mkdir -p /usr/local/bin/gupax/xmrig \
    && mv xmrig-6.26.0/xmrig /usr/local/bin/gupax/xmrig/ \
    && mv xmrig-6.26.0/config.json /usr/local/bin/gupax/xmrig/ \
    && rm -rf xmrig.tar.gz xmrig.sha256 xmrig-6.26.0

# --- Symlink gupax binary for easy access ---
RUN ln -s /usr/local/bin/gupax/gupax /usr/local/bin/gupax-bin \
    && chmod +x /usr/local/bin/gupax/gupax /usr/local/bin/gupax/p2pool/p2pool /usr/local/bin/gupax/xmrig/xmrig \
    && rm -rf /tmp/install

# Save version info
RUN echo "v2.0.1" > /tmp/guax_version \
    && echo "e64f6f774dc35352b8ae4397ccdb92ce0cc935cdfb100eac58d44e49f8796a01" > /tmp/p2pool_sha256 \
    && echo "ca82fc8426187880dffa502363849af6258e65fdb675a9cc9984a2b843854087" > /tmp/xmrig_sha256

# Labels
LABEL maintainer="w111a" \
      description="Gupax — GUI for P2Pool + XMRig Monero mining in Docker (noVNC enabled, bundled binaries)" \
      org.opencontainers.image.source="https://github.com/w111a/Gupax-docker" \
      org.opencontainers.image.version="v2.0.1-bundle" \
      guax.version="v2.0.1" \
      p2pool.version="v4.14" \
      xmrig.version="v6.26.0"

# Create Gupax state directory
RUN mkdir -p /home/miner/.local/state/gupax && chown -R miner:miner /home/miner

# Create index.html redirect at build time (avoids any runtime permission issues)
# This RUN executes as root, so we can write anywhere.
RUN echo '<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0;url=vnc.html"></head><body><a href="vnc.html">Click to connect</a></body></html>' > /usr/share/novnc/index.html

# Copy startup script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 6080 5900
EXPOSE 3333 37889 18080 18081 18082

VOLUME ["/home/miner/.local/state/gupax"]

USER miner
WORKDIR /home/miner

ENTRYPOINT ["/usr/local/bin/start.sh"]

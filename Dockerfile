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

# Detect latest Gupax version, fetch SHA256, download, verify, and install
WORKDIR /tmp/gupax
RUN VERSION=$(curl -fsSL https://api.github.com/repos/gupax-io/gupax/releases/latest \
           | python3 -c "import json,sys; print(json.load(sys.stdin)['tag_name'])") \
    && echo "Detected Gupax version: $VERSION" \
    && SHA=$(curl -fsSL "https://github.com/gupax-io/gupax/releases/download/$VERSION/SHA256SUMS" \
           | grep 'linux-x64.tar.gz' | awk '{print $1}') \
    && echo "SHA256: $SHA" \
    && curl -fsSL "https://github.com/gupax-io/gupax/releases/download/$VERSION/gupax-${VERSION}-linux-x64.tar.gz" \
           -o gupax.tar.gz \
    && printf '%s  %s\n' "$SHA" "gupax.tar.gz" | sha256sum --check --status \
    && tar -xzf gupax.tar.gz \
    && mv $(find . -name 'gupax' -type f) /usr/local/bin/gupax \
    && chmod +x /usr/local/bin/gupax \
    && rm -rf /tmp/gupax \
    && echo "${VERSION#v}" > /tmp/guax_version \
    && echo "$SHA" > /tmp/guax_sha256

# Labels
# Note: version label uses v-prefixed tag (v2.0.1) per upstream convention
LABEL maintainer="w111a" \
      description="Gupax — GUI for P2Pool + XMRig Monero mining in Docker (noVNC enabled)" \
      org.opencontainers.image.source="https://github.com/w111a/Gupax-docker" \
      org.opencontainers.image.version="$(cat /tmp/guax_version)" \
      guax.version="$(cat /tmp/guax_version)" \
      guax.sha256="$(cat /tmp/guax_sha256)"

# Create Gupax state directory
RUN mkdir -p /home/miner/.local/state/gupax && chown -R miner:miner /home/miner

# Copy startup script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 6080 5900
EXPOSE 3333 37889 18080 18081 18082

VOLUME ["/home/miner/.local/state/gupax"]

USER miner
WORKDIR /home/miner

ENTRYPOINT ["/usr/local/bin/start.sh"]

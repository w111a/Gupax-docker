# =============================================================================
# Gupax-docker — Dockerfile
# Gupax GUI for P2Pool + XMRig Monero mining
# Self-contained with noVNC — access via web browser at http://localhost:6080
#
# Build args (required):
#   GUPAX_VERSION  — Gupax release tag (auto-detected by CI)
#   GUPAX_SHA256   — SHA256 checksum for Gupax binary (auto-detected by CI)
#
# Ports:
#   6080 — noVNC web interface (connect your browser here)
#   5900 — VNC server (optional, for direct VNC access)
# =============================================================================

FROM ubuntu:22.04

# Prevent interactive tzdata prompt from blocking the build
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

LABEL maintainer="w111a"
LABEL description="Gupax — GUI for P2Pool + XMRig Monero mining in Docker (noVNC enabled)"
LABEL org.opencontainers.image.source="https://github.com/w111a/Gupax-docker"
LABEL org.opencontainers.image.version="${GUPAX_VERSION}"
LABEL guax.version="${GUPAX_VERSION}"
LABEL guax.sha256="${GUPAX_SHA256}"

# Build arguments — values injected by CI workflow
ARG GUPAX_VERSION
ARG GUPAX_SHA256

# Fail fast if version/sha not provided
RUN if [ -z "$GUPAX_VERSION" ] || [ -z "$GUPAX_SHA256" ]; then \
      echo "ERROR: GUPAX_VERSION and GUPAX_SHA256 must be set via --build-arg"; \
      echo "  GUPAX_VERSION=$GUPAX_VERSION"; \
      echo "  GUPAX_SHA256=$GUPAX_SHA256"; \
      exit 1; \
    fi

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

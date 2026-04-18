# =============================================================================
# Gupax-docker — Single-stage Dockerfile with pre-built static binaries
# Runs P2Pool + XMRig for decentralized Monero mining
#
# Build args:
#   P2POOL_VERSION    — P2Pool release tag (default: v4.14)
#   P2POOL_SHA256     — SHA256 checksum for P2Pool binary (required for verification)
#   XMRIG_VERSION     — XMRig release tag (default: 6.26.0)
#   XMRIG_SHA256      — SHA256 checksum for XMRig binary (required for verification)
#
# Example:
#   docker build --build-arg P2POOL_VERSION=v4.14 --build-arg P2POOL_SHA256=<hash> .
# =============================================================================

FROM ubuntu:22.04

LABEL maintainer="w111a"
LABEL description="Gupax-docker: P2Pool + XMRig for decentralized Monero mining"
LABEL org.opencontainers.image.source="https://github.com/w111a/Gupax-docker"

# Build arguments with defaults
ARG P2POOL_VERSION=v4.14
ARG P2POOL_SHA256
ARG XMRIG_VERSION=6.26.0
ARG XMRIG_SHA256

# URLs for pre-built static binaries
ENV P2POOL_URL="https://github.com/SChernykh/p2pool/releases/download/${P2POOL_VERSION}/p2pool-${P2POOL_VERSION}-linux-x64.tar.gz" \
    XMRIG_URL="https://github.com/xmrig/xmrig/releases/download/v${XMRIG_VERSION}/xmrig-${XMRIG_VERSION}-linux-static-x64.tar.gz"

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    libhwloc15 \
    libssl3 \
    libuv1 \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates \
    && groupadd -r miner \
    && useradd -r -g miner -m -d /home/miner miner

# Download, verify, and extract P2Pool
WORKDIR /tmp/p2pool
RUN set -eux; \
    curl -fsSL "$P2POOL_URL" -o p2pool.tar.gz; \
    printf '%s  %s\n' "$P2POOL_SHA256" "p2pool.tar.gz" | sha256sum --check --status; \
    tar -xzf p2pool.tar.gz --strip-components=1; \
    rm p2pool.tar.gz; \
    chmod +x p2pool

# Download, verify, and extract XMRig
WORKDIR /tmp/xmrig
RUN set -eux; \
    curl -fsSL "$XMRIG_URL" -o xmrig.tar.gz; \
    printf '%s  %s\n' "$XMRIG_SHA256" "xmrig.tar.gz" | sha256sum --check --status; \
    tar -xzf xmrig.tar.gz --strip-components=1; \
    rm xmrig.tar.gz; \
    chmod +x xmrig

# Copy binaries to final location
RUN mv /tmp/p2pool/p2pool /usr/local/bin/ && \
    mv /tmp/xmrig/xmrig /usr/local/bin/ && \
    rm -rf /tmp/p2pool /tmp/xmrig

# Create data directories
RUN mkdir -p /p2pool /monero && chown -R miner:miner /p2pool /monero

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose ports
# 3333  — P2Pool stratum server
# 37889 — P2Pool Monero node ZMQ
# 18080 — Monero P2P (optional local node)
# 18081 — Monero RPC (optional local node)
EXPOSE 3333 37889 18080 18081

# Persistent data
VOLUME ["/p2pool", "/monero"]

USER miner
WORKDIR /home/miner

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["--mini"]
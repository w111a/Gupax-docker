# =============================================================================
# Gupax-docker — Multi-stage Dockerfile
# Runs P2Pool + XMRig for decentralized Monero mining
#
# Build args (override with --build-arg):
#   P2POOL_VERSION  — P2Pool branch or tag (default: master)
#   XMRIG_VERSION   — XMRig branch or tag (default: main)
#
# Example:
#   docker build --build-arg P2POOL_VERSION=master --build-arg XMRIG_VERSION=main .
# =============================================================================

# Global build args — must be redeclared in each stage for RUN commands to access them
ARG P2POOL_VERSION=master
ARG XMRIG_VERSION=main

# ---------------------------------------------------------------------------
# Stage 1: Build P2Pool from source
# P2Pool repo: https://github.com/SChernykh/p2pool
# Default branch: master
# ---------------------------------------------------------------------------
FROM ubuntu:22.04 AS p2pool-builder

# Redeclare ARG so it is available in RUN commands within this stage
ARG P2POOL_VERSION=master

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    build-essential \
    cmake \
    git \
    libcurl4-openssl-dev \
    libssl-dev \
    libuv1-dev \
    libzmq3-dev \
    && rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates

# Clone P2Pool — default branch is "master"
RUN git clone --branch ${P2POOL_VERSION} --depth 1 https://github.com/SChernykh/p2pool.git /p2pool-src && echo "Cloned P2Pool ref: ${P2POOL_VERSION}"

WORKDIR /p2pool-src/build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release && make -j$(nproc)

# ---------------------------------------------------------------------------
# Stage 2: Build XMRig from source
# XMRig repo: https://github.com/xmrig/xmrig
# Default branch: main
# ---------------------------------------------------------------------------
FROM ubuntu:22.04 AS xmrig-builder

# Redeclare ARG so it is available in RUN commands within this stage
ARG XMRIG_VERSION=main

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    build-essential \
    cmake \
    git \
    libhwloc-dev \
    libssl-dev \
    libuv1-dev \
    && rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates

# Clone XMRig — default branch is "main" (NOT "master")
RUN git clone --branch ${XMRIG_VERSION} --depth 1 https://github.com/xmrig/xmrig.git /xmrig-src && echo "Cloned XMRig ref: ${XMRIG_VERSION}"

WORKDIR /xmrig-src/build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release && make -j$(nproc)

# ---------------------------------------------------------------------------
# Stage 3: Runtime image
# ---------------------------------------------------------------------------
FROM ubuntu:22.04 AS runtime

LABEL maintainer="w111a"
LABEL description="Gupax-docker: P2Pool + XMRig for decentralized Monero mining"
LABEL org.opencontainers.image.source="https://github.com/w111a/Gupax-docker"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    libhwloc15 \
    libssl3 \
    libuv1 \
    libzmq5 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -r miner \
    && useradd -r -g miner -m -d /home/miner miner

# Copy built binaries
COPY --from=p2pool-builder /p2pool-src/build/p2pool /usr/local/bin/p2pool
COPY --from=xmrig-builder /xmrig-src/build/xmrig /usr/local/bin/xmrig

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

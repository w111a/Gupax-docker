# =============================================================================
# Gupax-docker — Multi-stage Dockerfile
# Runs P2Pool + XMRig for decentralized Monero mining
# =============================================================================

# ---------------------------------------------------------------------------
# Stage 1: Build P2Pool from source
# ---------------------------------------------------------------------------
FROM ubuntu:22.04 AS p2pool-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    libcurl4-openssl-dev \
    libssl-dev \
    libuv1-dev \
    libzmq3-dev \
    && rm -rf /var/lib/apt/lists/*

ARG P2POOL_VERSION=v3.2
RUN git clone --branch ${P2POOL_VERSION} --depth 1 https://github.com/SChernykh/p2pool.git /p2pool-src

WORKDIR /p2pool-src/build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release && make -j$(nproc)

# ---------------------------------------------------------------------------
# Stage 2: Build XMRig from source
# ---------------------------------------------------------------------------
FROM ubuntu:22.04 AS xmrig-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    libhwloc-dev \
    libssl-dev \
    libuv1-dev \
    && rm -rf /var/lib/apt/lists/*

ARG XMRIG_VERSION=v6.22.0
RUN git clone --branch ${XMRIG_VERSION} --depth 1 https://github.com/xmrig/xmrig.git /xmrig-src

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

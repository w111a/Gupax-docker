#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Gupax-docker Entrypoint Script
# Orchestrates P2Pool and XMRig for decentralized Monero mining
# =============================================================================

# --- Defaults ---
: "${WALLET_ADDRESS:?ERROR: WALLET_ADDRESS environment variable must be set}"
: "${P2POOL_STRATUM_PORT:=3333}"
: "${P2POOL_MONERO_PORT:=37889}"
: "${XMRIG_THREADS:=0}"
: "${P2POOL_MINI:=true}"
: "${MONERO_NODE:=auto}"
: "${MONERO_RPC_PORT:=18081}"

P2POOL_ARGS=()
XMRIG_ARGS=()

# --- Build P2Pool arguments ---
if [ "$P2POOL_MINI" = "true" ]; then
    P2POOL_ARGS+=(--mini)
fi

# Determine Monero node connection
if [ "$MONERO_NODE" = "local" ] || [ "$MONERO_NODE" = "auto" ]; then
    # Connect to local Monero node (or external if not available)
    P2POOL_ARGS+=(
        --wallet "${WALLET_ADDRESS}"
        --stratum "0.0.0.0:${P2POOL_STRATUM_PORT}"
        --rpcport "${P2POOL_MONERO_PORT}"
    )
else
    # Remote node configuration
    : "${MONERO_RPC_HOST:=127.0.0.1}"
    P2POOL_ARGS+=(
        --wallet "${WALLET_ADDRESS}"
        --stratum "0.0.0.0:${P2POOL_STRATUM_PORT}"
        --host "${MONERO_RPC_HOST}"
        --rpcport "${MONERO_RPC_PORT}"
    )
fi

# --- Build XMRig arguments ---
XMRIG_ARGS+=(
    --url "127.0.0.1:${P2POOL_STRATUM_PORT}"
    --user "${WALLET_ADDRESS}"
    --pass "gupax-docker"
    --keepalive
    --donate-level 1
)

if [ "$XMRIG_THREADS" -gt 0 ]; then
    XMRIG_ARGS+=(--threads "${XMRIG_THREADS}")
fi

echo "============================================="
echo "  Gupax-docker — Decentralized Monero Mining"
echo "============================================="
echo ""
echo "  Wallet: ${WALLET_ADDRESS:0:10}...${WALLET_ADDRESS: -6}"
echo "  P2Pool Mini: ${P2POOL_MINI}"
echo "  P2Pool Stratum Port: ${P2POOL_STRATUM_PORT}"
echo "  XMRig Threads: ${XMRIG_THREADS} (0=auto)"
echo "  Monero Node: ${MONERO_NODE}"
echo ""
echo "============================================="

# --- Start P2Pool in background ---
echo "[*] Starting P2Pool..."
p2pool "${P2POOL_ARGS[@]}" &
P2POOL_PID=$!

# --- Wait for P2Pool stratum to be ready ---
echo "[*] Waiting for P2Pool stratum to be ready..."
MAX_RETRIES=60
RETRY=0
until nc -z 127.0.0.1 "${P2POOL_STRATUM_PORT}" 2>/dev/null || [ "$RETRY" -ge "$MAX_RETRIES" ]; do
    sleep 1
    RETRY=$((RETRY + 1))
done

if [ "$RETRY" -ge "$MAX_RETRIES" ]; then
    echo "[!] WARNING: P2Pool stratum not ready after ${MAX_RETRIES}s, starting XMRig anyway..."
else
    echo "[+] P2Pool stratum ready!"
fi

# --- Start XMRig in foreground ---
echo "[*] Starting XMRig..."
xmrig "${XMRIG_ARGS[@]}" &

# --- Wait for any process to exit ---
wait -n 2>/dev/null || wait

echo "[!] A process exited unexpectedly. Shutting down..."
kill "$P2POOL_PID" 2>/dev/null || true
exit 1

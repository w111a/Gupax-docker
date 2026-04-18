#!/usr/bin/env bash
# =============================================================================
# Get Checksums Script for Gupax-docker
# Fetches official SHA256 checksums from GitHub releases
# =============================================================================
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    cat << EOF
Usage: $(basename "$0") <p2pool|xmrig> <version>

Examples:
  $(basename "$0") p2pool v4.14
  $(basename "$0") xmrig 6.26.0
  $(basename "$0") p2pool latest
  $(basename "$0") xmrig latest

EOF
    exit 1
}

# Check arguments
if [[ $# -ne 2 ]]; then
    usage
fi

TOOL="$1"
VERSION="$2"

# Resolve latest if requested
if [[ "$VERSION" == "latest" ]]; then
    echo "[*] Resolving latest version for $TOOL..."
    if [[ "$TOOL" == "p2pool" ]]; then
        VERSION=$(curl -fsSL "https://api.github.com/repos/SChernykh/p2pool/releases/latest" | grep '"tag_name"' | sed 's/.*": "\([^"]*\)".*/\1/')
    elif [[ "$TOOL" == "xmrig" ]]; then
        VERSION=$(curl -fsSL "https://api.github.com/repos/xmrig/xmrig/releases/latest" | grep '"tag_name"' | sed 's/.*": "\([^"]*\)".*/\1/' | sed 's/^v//')
    fi
    echo "[*] Latest version: $VERSION"
fi

# Fetch checksums
fetch_p2pool() {
    local ver="$1"
    local url="https://github.com/SChernykh/p2pool/releases/download/${ver}/sha256sums.txt.asc"
    echo "[*] Fetching P2Pool checksums from: $url"
    
    local content
    content=$(curl -fsSL "$url")
    
    # Extract the linux-x64 checksum (PGP signed file has extra format)
    local checksum
    checksum=$(echo "$content" | grep "p2pool-${ver}-linux-x64.tar.gz" | awk '{print $1}')
    
    if [[ -z "$checksum" ]]; then
        echo -e "${RED}[ERROR]${NC} Could not find checksum for p2pool-${ver}-linux-x64.tar.gz"
        echo -e "${YELLOW}[HINT]${NC} Check if version ${ver} exists at https://github.com/SChernykh/p2pool/releases"
        exit 1
    fi
    
    echo -e "${GREEN}[OK]${NC} P2Pool ${ver} checksum:"
    echo "  P2POOL_VERSION=v${ver}"
    echo "  P2POOL_SHA256=${checksum}"
    echo ""
    echo "Add these to your .env or docker-compose.yml"
}

fetch_xmrig() {
    local ver="$1"
    local url="https://github.com/xmrig/xmrig/releases/download/v${ver}/SHA256SUMS"
    echo "[*] Fetching XMRig checksums from: $url"
    
    local checksum
    checksum=$(curl -fsSL "$url" | grep "xmrig-${ver}-linux-static-x64.tar.gz" | awk '{print $1}')
    
    if [[ -z "$checksum" ]]; then
        echo -e "${RED}[ERROR]${NC} Could not find checksum for xmrig-${ver}-linux-static-x64.tar.gz"
        echo -e "${YELLOW}[HINT]${NC} Check if version ${ver} exists at https://github.com/xmrig/xmrig/releases"
        exit 1
    fi
    
    echo -e "${GREEN}[OK]${NC} XMRig ${ver} checksum:"
    echo "  XMRIG_VERSION=${ver}"
    echo "  XMRIG_SHA256=${checksum}"
    echo ""
    echo "Add these to your .env or docker-compose.yml"
}

# Dispatch
case "$TOOL" in
    p2pool)
        fetch_p2pool "$VERSION"
        ;;
    xmrig)
        fetch_xmrig "$VERSION"
        ;;
    *)
        echo -e "${RED}[ERROR]${NC} Unknown tool: $TOOL"
        usage
        ;;
esac

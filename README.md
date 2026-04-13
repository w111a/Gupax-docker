# 🎮 Gupax-docker

> Docker packaging for [Gupax](https://github.com/hinto-janai/gupax) — the GUI that unites [P2Pool](https://github.com/SChernykh/p2pool) and [XMRig](https://github.com/xmrig/xmrig) for easy, decentralized Monero mining.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🐳 One-command setup | Run Gupax + P2Pool + XMRig with a single `docker compose up` |
| 🔗 Decentralized mining | P2Pool provides trustless, decentralized Monero mining |
| 💾 Persistent data | Blockchain and P2Pool data persist across container restarts |
| ⚙️ Configurable | Environment variables for wallet, mining threads, and more |
| 🔄 Auto-restart | Containers restart automatically on failure or system reboot |
| 🖥️ GUI support | X11 forwarding for the Gupax graphical interface |

---

## 📋 Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (v20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2.0+)
- A Monero wallet address (for mining payouts)
- (Optional) X11 display server for Gupax GUI on Linux

---

## 🚀 Quick Start

### Option A: Docker Compose (Recommended)

```bash
# 1. Clone the repository
git clone https://github.com/w111a/Gupax-docker.git
cd Gupax-docker

# 2. Set your wallet address
export WALLET_ADDRESS=4ABCDEF1234567890abcdef1234567890abcdef1234567890abcdef12345678

# 3. Start mining
docker compose up -d
```

### Option B: Docker Run

```bash
docker run -d \
  --name gupax \
  --restart unless-stopped \
  -e WALLET_ADDRESS=4ABCDEF1234567890abcdef1234567890abcdef1234567890abcdef12345678 \
  -p 3333:3333 \
  -p 37889:37889 \
  -v gupax-p2pool:/p2pool \
  -v gupax-monero:/monero \
  w111a/gupax-docker:latest
```

---

## ⚙️ Configuration

### Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `WALLET_ADDRESS` | ✅ Yes | — | Your Monero wallet address for mining payouts |
| `P2POOL_STRATUM_PORT` | No | `3333` | P2Pool stratum server port |
| `P2POOL_MONERO_PORT` | No | `37889` | P2Pool Monero node port |
| `XMRIG_THREADS` | No | `0` (auto) | Number of mining CPU threads (0 = auto-detect) |
| `P2POOL_MINI` | No | `true` | Use P2Pool mini sidechain (recommended for most miners) |
| `MONERO_NODE` | No | `auto` | Use `local` for built-in node, `remote` for external, `auto` to decide |

### Ports

| Port | Protocol | Service | Description |
|---|---|---|---|
| `3333` | TCP | P2Pool | Stratum server for miners |
| `37889` | TCP | P2Pool | Monero node ZMQ port |
| `18080` | TCP | Monerod | Monero P2P network port (if running local node) |
| `18081` | TCP | Monerod | Monero RPC port (if running local node) |

### Volumes

| Volume | Path | Description |
|---|---|---|
| `gupax-p2pool` | `/p2pool` | P2Pool database and share data |
| `gupax-monero` | `/monero` | Monero blockchain data |

---

## 🔗 Official Resources

- [Gupax](https://github.com/hinto-janai/gupax) — The GUI unifying P2Pool & XMRig
- [P2Pool](https://github.com/SChernykh/p2pool) — Decentralized Monero mining pool
- [XMRig](https://github.com/xmrig/xmrig) — High-performance Monero miner
- [Monero](https://www.getmonero.org/) — Private, decentralized cryptocurrency

---

## ⚠️ Disclaimer

**Mining cryptocurrency consumes significant electricity and may not be profitable depending on your hardware, electricity costs, and market conditions.** This project is provided as-is for educational and convenience purposes. Always do your own research before investing in mining hardware or cryptocurrency. The maintainers of this repository are not responsible for any financial losses.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

Gupax, P2Pool, and XMRig are each licensed under their respective licenses — see the official repositories linked above.

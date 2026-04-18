test

> ⚠️ **WORK IN PROGRESS — NOT READY FOR USE** ⚠️
>
> This project is under active development and is **not yet functional**. Do not use it for mining or in production. Features may be incomplete, broken, or change at any time. Check back later or star the repo for updates.

<img src="https://raw.githubusercontent.com/gupax-io/gupax/main/assets/images/banner.png" width="600">

[![Docker Pulls](https://img.shields.io/docker/pulls/w111a/gupax-docker?style=flat-square&logo=docker&label=pulls&color=blue)](https://hub.docker.com/r/w111a/gupax-docker)
[![Build Status](https://img.shields.io/github/actions/workflow/status/w111a/Gupax-docker/docker-publish.yml?branch=main&style=flat-square&logo=github&label=build)](https://github.com/w111a/Gupax-docker/actions)
[![License](https://img.shields.io/github/license/w111a/Gupax-docker?style=flat-square&color=blue)](https://github.com/w111a/Gupax-docker/blob/main/LICENSE)
[![Image Size](https://img.shields.io/docker/image-size/w111a/gupax-docker/latest?style=flat-square&logo=docker&color=blueviolet)](https://hub.docker.com/r/w111a/gupax-docker)

> Docker packaging for [Gupax](https://github.com/hinto-janai/gupax) — the GUI that unites [P2Pool](https://github.com/SChernykh/p2pool) and [XMRig](https://github.com/xmrig/xmrig) for easy, decentralized <img src="https://cdn4.iconfinder.com/data/icons/logos-and-brands/512/221_Monero_logo_logos-512.png" width="20" style="vertical-align:middle;"> Monero mining.

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
| 🟠 Unraid support | Pre-built template for easy install via Community Applications |

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

## 🟠 Unraid Installation

Gupax-docker includes a pre-built [Unraid template](templates/gupax-docker.xml) so you can install it directly from the Unraid Community Applications (CA) plugin — no command line needed.

### Install via Community Applications

1. **Install the Community Applications plugin** (if you haven't already):
   - Go to the [CA Plugin page](https://forums.unraid.net/topic/38582-plug-in-community-applications/) and follow the installation instructions.
2. **Search for Gupax-docker** in the Apps tab of your Unraid webGUI.
3. **Click Install** — the template will auto-populate all settings.
4. **Set your wallet address** — fill in the `WALLET_ADDRESS` field with your Monero wallet address.
5. **Click Apply** — the container will start mining automatically.

### Manual Install via Unraid Docker Tab

If you prefer not to use Community Applications, you can add the template manually:

1. Go to **Docker** → **Add Container** in the Unraid webGUI.
2. Set **Template Repository** to:
   ```
   https://github.com/w111a/Gupax-docker
   ```
3. Select the **gupax-docker** template from the dropdown.
4. Fill in the `WALLET_ADDRESS` field (required).
5. Adjust other settings as needed (threads, P2Pool mini, ports).
6. Click **Apply** to start the container.

### Unraid Template Fields

| Field | Required | Default | Description |
|---|---|---|---|
| `WALLET_ADDRESS` | ✅ Yes | — | Your Monero wallet address for mining payouts |
| `P2POOL_MINI` | No | `true` | Use P2Pool mini sidechain (recommended) |
| `XMRIG_THREADS` | No | `0` | CPU threads for mining (0 = auto) |
| `MONERO_NODE` | No | `auto` | Monero node: `auto`, `local`, or `remote` |
| `P2POOL_STRATUM_PORT` | No | `3333` | P2Pool stratum server port |
| `P2POOL_MONERO_PORT` | No | `37889` | P2Pool Monero node ZMQ port |

### Unraid Volumes

The template automatically creates persistent volumes under `/mnt/user/appdata/gupax-docker/`:

| Unraid Path | Container Path | Description |
|---|---|---|
| `.../gupax-docker/p2pool` | `/p2pool` | P2Pool database and share data |
| `.../gupax-docker/monero` | `/monero` | Monero blockchain data |

> **Tip:** Place the `monero` volume on a fast drive (SSD/cache pool) for best sync performance.

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

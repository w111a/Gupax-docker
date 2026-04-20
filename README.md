<img src="https://raw.githubusercontent.com/gupax-io/gupax/main/assets/images/banner.png" width="600">

> [!WARNING]
> **⚠️ Work in Progress — Not Ready for Use**
> This project is actively under development. The Docker setup, configuration, and behavior may change at any time. Do not use in production or with real funds until a stable release is published.


[![Build Status](https://img.shields.io/github/actions/workflow/status/w111a/Gupax-docker/docker-publish.yml?branch=main&style=flat-square&logo=github&label=build)](https://github.com/w111a/Gupax-docker/actions)
[![License](https://img.shields.io/github/license/w111a/Gupax-docker?style=flat-square&color=blue)](https://github.com/w111a/Gupax-docker/blob/main/LICENSE)
[![Docker Hub](https://img.shields.io/docker/pulls/libre7/gupax-docker?style=flat-square&color=blue&logo=docker)](https://hub.docker.com/r/libre7/gupax-docker)
[![Image Size](https://img.shields.io/docker/image-size/libre7/gupax-docker/latest?style=flat-square&logo=docker&color=blueviolet)](https://hub.docker.com/r/libre7/gupax-docker)

> Docker packaging for [Gupax](https://github.com/hinto-janai/gupax) — the GUI that unites [P2Pool](https://github.com/SChernykh/p2pool) and [XMRig](https://github.com/xmrig/xmrig) for easy, decentralized Monero mining.

**Self-contained with noVNC** — access the Gupax GUI directly from your web browser. No X11 server or additional setup needed.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🌐 **Browser Access** | noVNC web interface — just open `http://localhost:6080` |
| 🖥️ Gupax GUI | Full graphical interface for P2Pool + XMRig mining |
| 🔗 Decentralized mining | P2Pool provides trustless, decentralized Monero mining |
| 💾 Persistent config | Gupax settings persist across container restarts |
| 🔄 Auto-restart | Container restarts automatically on failure |
| 📊 Mining dashboard | Real-time hashrate, shares, payouts, and node status |
| 🔧 XMRig proxy | Built-in proxy for connecting external miners |

---

## 📋 Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (v20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2.0+)
- A Monero wallet address (for mining payouts)
- A web browser (any modern browser)

---

## 🚀 Quick Start

### Option 1: Docker Compose (recommended)

```bash
# 1. Clone the repository
git clone https://github.com/w111a/Gupax-docker.git
cd Gupax-docker

# 2. Copy and edit environment file
cp .env.example .env

# 3. Start the container
docker compose up -d

# 4. Open your browser
open http://localhost:6080
```

```bash
# Pull and run
docker run -d \
  --name gupax \
  -p 6080:6080 \
  -p 3333:3333 \
  -p 37889:37889 \
  -p 18080:18080 \
  -p 18081:18081 \
  -p 18082:18082 \
  -v gupax-config:/home/miner/.local/state/gupax \
  -v gupax-monero:/home/miner/.bitmonero \
  libre7/gupax-docker:latest

# Open browser
open http://localhost:6080
```

Click **Connect** on the noVNC page — no password required by default.

---

## 🔧 Configuration

### Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `MONERO_DATA_PATH` | No | gupax-monero | Path to Monero blockchain data |

> **Note:** `GUPAX_VERSION` and `GUPAX_SHA256` are managed automatically by the CI workflow — no manual configuration needed. The Docker image is always built with the latest detected upstream Gupax version.

### Ports

**Access (user-facing)**

| Port | Service | Description |
|---|---|---|
| `6080` | noVNC | **Web UI** — open in your browser to use Gupax |
| `5900` | VNC | Direct VNC client access (optional) |

**P2Pool (mining stratum)**

| Port | Service | Description |
|---|---|---|
| `3333` | P2Pool | Stratum server — external miners connect here |
| `37889` | P2Pool | Monero node ZMQ |

**Monero node (monerod)**

| Port | Service | Description |
|---|---|---|
| `18080` | monerod | P2P network — connects to other Monero nodes |
| `18081` | monerod | RPC — JSON-RPC API for Gupax |
| `18082` | monerod | RPC ZMQ — subscription-based block updates |


### Volumes

| Volume | Path | Description |
|---|---|---|
| `gupax-config` | `/home/miner/.local/state/gupax` | Gupax configuration and state |
| `gupax-monero` (or host path) | `/home/miner/.bitmonero` | Monero blockchain data |

### Using an Existing Blockchain

If you have an existing Monero blockchain directory, you can mount it directly.

First start the container to create the volume:

```bash
docker compose up -d
```

Then in the Gupax GUI, go to the **Node tab** and set the database path to:
```
/home/miner/.bitmonero
```

Alternatively, pre-populate the volume before starting:

```bash
# Copy your blockchain to the volume
docker run --rm -v gupax-monero:/data -v /path/to/your/blockchain:/source alpine cp -r /source /data/

# Or use a host directory directly in docker-compose.yml:
# volumes:
#   - /path/to/your/blockchain:/home/miner/.bitmonero
```

---

## 🔐 Security Notes

- The noVNC interface has **no password by default**
- Only expose port 6080 to trusted networks
- For production use, consider adding authentication at the network level

---

## 🐛 Troubleshooting

### Gupax appears blank or black in the browser

Try refreshing the page and waiting 10-20 seconds for Gupax to fully initialize. If the issue persists, restart the container:

```bash
docker compose restart
```

### Connection refused on port 6080

Make sure the container is running:

```bash
docker compose logs
docker compose ps
```

### Container keeps restarting

Check the logs:

```bash
docker compose logs
```

---

## 🔗 Official Resources

- [Gupax](https://github.com/hinto-janai/gupax) — The GUI unifying P2Pool & XMRig
- [P2Pool](https://github.com/SChernykh/p2pool) — Decentralized Monero mining pool
- [XMRig](https://github.com/xmrig/xmrig) — High-performance Monero miner
- [Monero](https://www.getmonero.org/) — Private, decentralized cryptocurrency
- [noVNC](https://github.com/novnc/noVNC) — HTML5 VNC client

---

## ⚠️ Disclaimer

**Mining cryptocurrency consumes significant electricity and may not be profitable depending on your hardware, electricity costs, and market conditions.** This project is provided as-is for educational and convenience purposes. Always do your own research before investing in mining hardware or cryptocurrency. The maintainers of this repository are not responsible for any financial losses.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

Gupax, P2Pool, and XMRig are each licensed under their respective licenses — see the official repositories linked above.

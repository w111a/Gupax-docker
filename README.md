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
| 🧅 Tor | Optional Tor onion hidden service for Monero P2P & SOCKS5 proxy |

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
  -v gupax-config:/home/miner/.local/share/gupax \
  -v gupax-monero:/home/miner/.bitmonero \
  libre7/gupax-docker:latest

# Open browser
open http://localhost:6080
```

Click **Connect** on the noVNC page — no password required by default.

---

## 🖥️ Unraid Setup

This section covers installing and running Gupax-docker on Unraid.

### Prerequisites

- A running Unraid server (v6.12+)
- The [Community Applications](https://forums.unraid.net/topic/38582-plug-in-community-applications/) plugin installed

### Installing via Community Applications (Recommended)

1. Open the **Apps** tab in your Unraid web UI
2. Search for **"gupax"** or **"monero mining"**
3. Click **Install**
4. Set **SCREEN_RESOLUTION** if needed (default: `1920x1080x24`)
5. Click **Apply** and wait for the container to start

### Installing via Template URL

If Gupax-docker is not yet in the Community Applications store:

1. Go to the **Docker** tab in your Unraid web UI
2. Click **Add Container**
3. Set the **Template URL** to:
   ```
   https://raw.githubusercontent.com/w111a/gupax-docker/main/templates/gupax-docker.xml
   ```
4. Fill in the required fields — set **TOR_ENABLED** and **SCREEN_RESOLUTION** as needed
5. Click **Apply**

### Accessing the GUI

Once the container is running:

1. Open your browser and go to:
   ```
   http://your-unraid-ip:6080
   ```
2. Click **Connect** on the noVNC page — no password required
3. The Gupax GUI will appear

### Setting Your Wallet Address

Inside the Gupax GUI:

1. Go to the **Node tab** (or **Settings tab** depending on your Gupax version)
2. Enter your Monero wallet address in the **Wallet Address** field
3. Save the settings

> **Note:** The wallet address is set inside the Gupax GUI itself — it is **not** a Docker environment variable or template field.

### Ports on Unraid

The following ports are exposed by default. You do not need to open all of them — only the ones you use:

| Port | Service | Who needs it |
|---|---|---|
| `6080` | noVNC Web UI | **Everyone** — access Gupax in your browser |
| `5900` | VNC | Optional — direct VNC clients |
| `3333` | P2Pool Stratum | External miners connecting to your P2Pool |
| `37889` | P2Pool ZMQ | External miners; leave at default |
| `18080` | Monero P2P | Only if running a full Monero node (optional) |
| `18081` | Monero RPC | Only if running a full Monero node (optional) |

### Using Your Own Blockchain on Unraid

If you have an existing Monero blockchain on your Unraid server:

1. In the template, map your blockchain directory to `/home/miner/.bitmonero` as a volume
2. Start the container once to ensure the path is created
3. In the Gupax GUI, go to the **Node tab** and set the database path to:
   ```
   /home/miner/.bitmonero
   ```

---

## 🔧 Configuration

### Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `TOR_ENABLED` | No | `false` | Enable Tor SOCKS5 proxy and hidden service for Monero P2P |
| `VNC_PASSWORD` | No | *(empty)* | Set to require VNC authentication. Leave empty for no password |
| `SCREEN_RESOLUTION` | No | `1920x1080x24` | Display resolution for the noVNC/Gupax GUI |
| `MONERO_DATA_PATH` | No | `gupax-monero` | Path to Monero blockchain data (host-mounted volume) |

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
| `gupax-config` | `/home/miner/.local/share/gupax` | Gupax configuration and state |
| `gupax-monero` (or host path) | `/home/miner/.bitmonero` | Monero blockchain data |
| `gupax-tor` (optional) | `/home/miner/.tor` | Tor hidden service keys (for persistent .onion address) |

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

## 🧅 Tor Hidden Service (Optional)

Gupax-docker can optionally run a Tor daemon inside the container to provide:

- **SOCKS5 proxy** (`127.0.0.1:9050`) for outbound Monero P2P connections via Tor
- **Onion hidden service** — exposes your Monero node's P2P port (`18080`) as a `.onion` address for anonymous inbound connections

### Enabling Tor

Set `TOR_ENABLED=true` in your environment:

```bash
docker run -d \
  --name gupax \
  -e TOR_ENABLED=true \
  -p 6080:6080 \
  -p 18080:18080 \
  libre7/gupax-docker:latest
```

Or in `docker-compose.yml`:

```yaml
services:
  gupax:
    image: libre7/gupax-docker:latest
    environment:
      - TOR_ENABLED=true
```

### Tor Configuration

When `TOR_ENABLED=true`, the container automatically:

1. Starts the Tor daemon
2. Waits for the SOCKS5 proxy to be ready
3. Generates an **ephemeral hidden service** for `127.0.0.1:18080`
4. Displays the `.onion` address in the container logs

### Using Tor in Gupax

When Tor is enabled, the container logs will show:

```
[+] Tor SOCKS proxy is ready (127.0.0.1:9050)
[+] Monero node hidden service: abc123...xyz.onion
[+] Recommended monerod arguments:
    --proxy=127.0.0.1:9050
    --anonymous-inbound=abc123...xyz,127.0.0.1:18080,40
```

In Gupax, go to the **Node tab** and paste both arguments into the **Arguments** field:

```
--proxy=127.0.0.1:9050 --anonymous-inbound=abc123...xyz,127.0.0.1:18080,40
```

> **Note:** The `.onion` address is ephemeral — it changes every time the container is recreated. If you need a persistent address, mount a volume at `/home/miner/.tor`.

### Tor Data Persistence

The hidden service private key is stored in `/home/miner/.tor/hs_monerod/`. To keep the same address across restarts:

```yaml
volumes:
  - gupax-tor:/home/miner/.tor
```

The reference file `/home/miner/.tor/monerod_onion.txt` contains the current `.onion` address and recommended arguments.

### Security Considerations

- The hidden service only exposes port `18080` (Monero P2P), **not** RPC ports
- Port `9050` is bound to `127.0.0.1` inside the container and not exposed externally
- Consider firewall rules to block inbound to `18080` if you only want outbound Tor

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

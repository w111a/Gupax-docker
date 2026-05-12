<img src="https://raw.githubusercontent.com/gupax-io/gupax/main/assets/images/banner.png" width="600">

[![Build Status](https://img.shields.io/github/actions/workflow/status/libre-7/Gupax-docker/docker-publish.yml?branch=main&style=flat-square&logo=github&label=build)](https://github.com/libre-7/Gupax-docker/actions)
[![License](https://img.shields.io/github/license/libre-7/Gupax-docker?style=flat-square&color=blue)](https://github.com/libre-7/Gupax-docker/blob/main/LICENSE)
[![Docker Hub](https://img.shields.io/docker/pulls/libre7/gupax-docker?style=flat-square&color=blue&logo=docker)](https://hub.docker.com/r/libre7/gupax-docker)
[![Image Size](https://img.shields.io/docker/image-size/libre7/gupax-docker/latest?style=flat-square&logo=docker&color=blueviolet)](https://hub.docker.com/r/libre7/gupax-docker)

> Docker packaging for [Gupax](https://github.com/hinto-janai/gupax) — the GUI that unites [P2Pool](https://github.com/SChernykh/p2pool) and [XMRig](https://github.com/xmrig/xmrig) for easy, decentralized Monero mining. Optional built-in **🧅 Tor hidden service** for private transaction relay.

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
| 🧅 Tor hidden service | Optional — expose your node as a `.onion` for private transactions |

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
git clone https://github.com/libre-7/Gupax-docker.git
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


## 🧅 Tor (Optional)

When `TOR_ENABLED=true`, the container starts a Tor daemon with a **SOCKS5 proxy** on `127.0.0.1:9050` and a **hidden service** that exposes your Monero node's transaction-relay port as a `.onion` address. The container uses **tx-only mode** — P2P blockchain sync stays on clearnet; only wallet-originated transactions are routed through Tor hidden services. This keeps bandwidth through Tor negligible while still protecting transaction privacy. For the full rationale, see [issue #27](https://github.com/libre-7/Gupax-docker/issues/27).

> **Note:** Currently you must manually configure monerod to use Tor. The goal is to make this automatic in a future release — see [#12](https://github.com/libre-7/Gupax-docker/issues/12) for tracking.

### Step-by-Step: Configuring monerod to Use Tor

**1. Find your `.onion` address in the container logs**

```bash
docker logs gupaxtornode2 2>&1 | grep -A5 "Monero node hidden service"
```

You'll see output like:

```
[+] Monero node hidden service: dqwj5fyc4xfjnlswv2b4xjayxo2enr5sjgwjlimlvgeejkudo6msmqqd.onion
[+] Recommended monerod arguments (Gupax → Node → Arguments):
    --restricted-rpc
    --no-igd
    --tx-proxy=tor,127.0.0.1:9050
    --anonymous-inbound=dqwj5fyc...onion:18084,127.0.0.1:18086,40

[+] Wallet connection (Monero wallet / monero-wallet-cli / monero-wallet-rpc):
    dqwj5fyc...onion:18089
```

**2. Open the Gupax web UI** at `http://your-server:6080`

**3. Go to the Node tab** and switch from **Simple** to **Advanced** mode to reveal the **"Start options:"** text box

**4. ⚠️ Fix the `--data-dir` path first.** Gupax's default is the relative path `.bitmonero`, which does not resolve correctly in this Docker setup. In the Start options box, locate `--data-dir` and change it to the absolute path:

```
--data-dir /home/miner/.bitmonero
```

> **Why this matters:** Every time you click "Reset to Advanced options" or switch between Simple/Advanced modes, Gupax resets `--data-dir` back to `.bitmonero`. If left as the relative path, monerod will fail to find the blockchain and exit immediately. You must manually correct this each time the options are reset.

**5. Paste the four Tor arguments** from the log output (after the `--data-dir` fix):

```
--restricted-rpc --no-igd --tx-proxy=tor,127.0.0.1:9050 --anonymous-inbound=dqwj5fyc...onion:18084,127.0.0.1:18086,40
```

The complete Start options line should look like:

```
--data-dir /home/miner/.bitmonero --zmq-pub tcp://127.0.0.1:18083 --rpc-bind-ip 127.0.0.1 --rpc-bind-port 18081 --out-peers 8 --in-peers 16 --log-level 0 --sync-pruned-blocks --enable-dns-blocklist --disable-dns-checkpoints --prune-blockchain --restricted-rpc --no-igd --tx-proxy=tor,127.0.0.1:9050 --anonymous-inbound=dqwj5fyc...onion:18084,127.0.0.1:18086,40
```

**6. Click Save** (Gupax does not auto-save — if you skip this, the arguments are lost on restart)

**7. Click Start** to launch monerod with Tor

**8. ⚠️ Fix P2Pool's ZMQ port.** Gupax has a known bug where it copies the RPC port (`18081`) into P2Pool's `--zmq-port` argument. ZMQ is a different protocol on a different port (`18083`, set by `--zmq-pub tcp://127.0.0.1:18083` on monerod). If `--zmq-port 18081` is left as-is, P2Pool won't receive real-time block notifications from monerod.

Open the **P2Pool tab** → **Advanced** mode → **Arguments**, and change:
```
--zmq-port 18081
```
to:
```
--zmq-port 18083
```
Then click **Save**.

### Keeping the Same .onion Across Restarts

Mount the `gupax-tor` volume (enabled by default in `docker-compose.yml`) to persist the hidden service private key at `/home/miner/.tor/hs_monerod/hs_ed25519_secret_key`. As long as that file survives, your `.onion` address stays the same across container recreations.

### Connecting a Wallet via Tor

Once monerod is running, you can connect any Monero wallet through the same `.onion` address over the wallet RPC port (default `18089`, configurable via `TOR_RPC_PORT`).

**With a Monero wallet:**
1. Go to wallet settings / nodes
2. Add a remote node: `<onion>:18089` (e.g. `dqwj5fyc...onion:18089`)
3. The wallet syncs and submits transactions entirely through Tor

**With `monero-wallet-cli`:**
```bash
monero-wallet-cli --daemon-address <onion>:18089 --proxy 127.0.0.1:9050
```

> **How it works:** The hidden service forwards `:18089` (or your custom `TOR_RPC_PORT`) → monerod's JSON-RPC at `127.0.0.1:18081`. Wallet sync (`get_blocks.bin`) and transaction submission (`send_raw_transaction`) both flow through this port. Transaction broadcast from monerod to the network uses `--tx-proxy=tor,...` to route through SOCKS5.

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
   https://raw.githubusercontent.com/libre-7/gupax-docker/main/templates/gupax-docker.xml
   ```
4. Fill in the required fields — only **SCREEN_RESOLUTION** is configurable
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
| `37889` | P2Pool | P2P — p2pool peer connections (default `--p2p` port) |

**Monero node (monerod)**

| Port | Service | Description |
|---|---|---|
| `18080` | monerod | P2P network — connects to other Monero nodes |
| `18081` | monerod | RPC — JSON-RPC API for Gupax |
| `18083` | monerod | ZMQ pub — block notifications for P2Pool (internal, `--zmq-pub` flag) |


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

#### Ownership Requirements for Existing Blockchain Files

If you mount an existing blockchain from a host directory (not a fresh Docker volume), the container must have **read and write** permission to those files. The container runs Gupax as the user owning the `gupax-data` volume — auto-detected at startup or set via `PUID`/`PGID`.

If the container UID does not match the blockchain file owner, monerod will fail immediately:

```
Node | Stopped ... Uptime was: [1s], Exit status: [Failed]
```

**To check and fix ownership:**

```bash
# 1. Find the container's expected UID/GID
#    Check PUID/PGID env vars in docker-compose.yml or Unraid template.
#    Default on Unraid: 99:100 (nobody:users)

# 2. Check current ownership of your blockchain files
ls -ln /path/to/your/blockchain/lmdb/data.mdb

# 3. Change ownership to match the container (example for Unraid: 99:100)
chown -R 99:100 /path/to/your/blockchain
```

> **⚠️ Unraid FUSE caveat:** If your blockchain is on a **user share** path like `/mnt/user/appdata/...`, `chown` will appear to succeed but have **no effect** — Unraid's FUSE overlay filesystem (shfs) silently ignores ownership changes. Use the **direct disk or cache path** instead:
>
> ```bash
> # Correct — bypasses FUSE:
> chown -R 99:100 /mnt/cache/appdata/gupax/monero
> # or
> chown -R 99:100 /mnt/disk1/appdata/gupax/monero
> ```
>
> Verify from inside the container after changing ownership:
> ```bash
> docker exec gupaxtornode2 stat /home/miner/.bitmonero/lmdb/data.mdb | grep Uid
> # Should show: Uid: (99/nobody) — not 999/miner
> ```

> **Tip:** If you're unsure which UID the container uses, check the startup logs:
> ```
> [*] Running Gupax as UID:99 GID:100
> ```
> Then run `chown -R <UID>:<GID> /path/to/your/blockchain` to match.

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
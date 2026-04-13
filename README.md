# 🚀 Gupax-docker

**Decentralized Monero mining with P2Pool + XMRig in a single Docker container**

Inspired by [Gupax](https://github.com/hinto-janai/gupax), this container packages P2Pool (decentralized mining pool) and XMRig (high-performance CPU miner) together so you can start mining Monero trustlessly with a single command.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🏊 P2Pool | Decentralized, trustless mining pool — no operator, no fees, no middleman |
| ⛏️ XMRig | High-performance, open-source Monero CPU miner |
| 🔗 Auto Orchestration | P2Pool starts first, XMRig connects automatically |
| 🐳 Docker-first | One container, one command, zero hassle |
| 📦 Persistent Data | Blockchain & share data survives restarts via Docker volumes |
| 🖥️ Unraid Support | Install directly via Community Applications or Docker template |

---

## 🚀 Quick Start

### Docker Compose (Recommended)

1. Clone this repo:

```bash
git clone https://github.com/w111a/Gupax-docker.git
cd Gupax-docker
```

2. Set your Monero wallet address:

```bash
export WALLET_ADDRESS=4AdUndXHHZ6cfufTMvppY6JwXN75MUEusn54qB8Q4J7RWRL7mQGXn3M4GCQ7SdfmZAJ6b8CRuA6bJ4Uu6RzF5VwGSm8nWx
```

3. Start mining:

```bash
docker compose up -d
```

That's it! P2Pool will sync and XMRig will begin mining once P2Pool is ready.

### Docker CLI

```bash
docker run -d \
  --name gupax \
  --restart unless-stopped \
  -p 3333:3333 \
  -p 37889:37889 \
  -p 18080:18080 \
  -p 18081:18081 \
  -e WALLET_ADDRESS=4AdUndXHHZ6cfufTMvppY6JwXN75MUEusn54qB8Q4J7RWRL7mQGXn3M4GCQ7SdfmZAJ6b8CRuA6bJ4Uu6RzF5VwGSm8nWx \
  -e P2POOL_MINI=true \
  -v gupax-p2pool:/p2pool \
  -v gupax-monero:/monero \
  w111a/gupax-docker
```

---

## 🖥️ Unraid Installation

Gupax-docker can be installed on Unraid in two ways:

### Method 1: Community Applications (Recommended)

Once the template is merged into the [Community Applications](https://unraid.net/community/apps) repository, you can install directly:

1. Open the **Apps** tab in your Unraid web GUI
2. Search for **"gupax"** or **"gupax-docker"**
3. Click **Install**
4. Fill in the required fields:
   - **WALLET_ADDRESS** — Your Monero wallet address for payouts *(required)*
   - **P2POOL_MINI** — Set to `true` for the mini sidechain *(recommended for most miners)*
   - **XMRIG_THREADS** — Number of CPU threads (`0` = auto-detect)
5. Click **Apply** — the container will download and start automatically

### Method 2: Manual Template Install

If the template isn't yet in Community Applications, you can add it manually:

1. In Unraid, go to **Docker** tab → click **Add Container**
2. Click **Template** dropdown → select **Choose a template** → click **Add a new template**
3. Name it `gupax-docker` and paste the URL of the raw XML template:
   ```
   https://raw.githubusercontent.com/w111a/Gupax-docker/main/templates/gupax-docker.xml
   ```
4. The template fields will auto-populate — fill in your **WALLET_ADDRESS**
5. Click **Apply** to pull the image and start the container

### Unraid Configuration Tips

| Setting | Recommendation |
|---|---|
| **P2POOL_MINI** | `true` — the mini sidechain has lower difficulty, ideal for solo/small miners |
| **XMRIG_THREADS** | Set to 1–2 threads less than your total CPUs to leave headroom for Unraid |
| **MONERO_NODE** | `auto` — P2Pool will use a remote node if no local node is available |
| **Appdata Path** | Default `/mnt/user/appdata/gupax-docker/` is fine for persistent data |
| **CPU Pinning** | In Unraid, you can pin specific CPUs under the container settings to avoid contention with other containers |

> **💡 Tip:** If you want to run a full Monero node alongside P2Pool, set `MONERO_NODE=local`. This requires ~150GB of storage and significant initial sync time but provides the most privacy.

---

## ⚙️ Configuration

All configuration is done via environment variables:

| Variable | Default | Description |
|---|---|---|
| `WALLET_ADDRESS` | *(required)* | Your Monero wallet address for mining payouts |
| `P2POOL_MINI` | `true` | Use P2Pool mini sidechain (lower difficulty, faster payouts) |
| `XMRIG_THREADS` | `0` | Number of CPU threads for mining (0 = auto-detect) |
| `MONERO_NODE` | `auto` | Monero node mode: `auto`, `local`, or `remote` |
| `P2POOL_STRATUM_PORT` | `3333` | P2Pool stratum server port |
| `P2POOL_MONERO_PORT` | `37889` | P2Pool Monero node ZMQ port |
| `MONERO_P2P_PORT` | `18080` | Monero P2P network port |
| `MONERO_RPC_PORT` | `18081` | Monero RPC port |

---

## 📂 Volumes

| Container Path | Purpose |
|---|---|
| `/p2pool` | P2Pool database and share data (persistent) |
| `/monero` | Monero blockchain data if running a local node (persistent) |

---

## 🌐 Ports

| Port | Protocol | Purpose |
|---|---|---|
| `3333` | TCP | P2Pool stratum server — connect your miners here |
| `37889` | TCP | P2Pool Monero node ZMQ port |
| `18080` | TCP | Monero P2P network port (local node) |
| `18081` | TCP | Monero RPC port (local node) |

---

## 🔧 Connecting Additional Miners

Once the container is running, any machine on your network can point its miner at the P2Pool stratum:

```bash
# Example: running a separate XMRig on another machine
./xmrig --url=YOUR_UNRAID_IP:3333 --user=YOUR_WALLET_ADDRESS
```

Or add another XMRig container pointing to the same P2Pool instance.

---

## 🏗️ Building from Source

```bash
git clone https://github.com/w111a/Gupax-docker.git
cd Gupax-docker
docker build -t w111a/gupax-docker .
```

---

## ⚠️ Disclaimer

- **Mining cryptocurrency consumes electricity.** Ensure your power costs are viable before mining.
- **P2Pool is decentralized** — there is no operator to contact for support if payouts don't occur as expected.
- **This project is not affiliated with** the official [Gupax](https://github.com/hinto-janai/gupax) GUI project. It is inspired by and complementary to it.
- **Always verify your wallet address** before starting the container. Incorrect addresses will result in lost payouts.

---

## 📜 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

P2Pool is licensed under the [GPLv3](https://github.com/SChernykh/p2pool/blob/master/LICENSE).
XMRig is licensed under the [GPLv3](https://github.com/xmrig/xmrig/blob/master/LICENSE).

---

## 🙏 Credits

- [P2Pool](https://github.com/SChernykh/p2pool) — Decentralized Monero mining pool by SChernykh
- [XMRig](https://github.com/xmrig/xmrig) — High-performance Monero miner
- [Gupax](https://github.com/hinto-janai/gupax) — The original Gupax GUI that inspired this project
- [Monero](https://www.getmonero.org/) — Private, decentralized cryptocurrency

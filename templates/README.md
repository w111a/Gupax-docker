# Unraid Docker Templates

This directory contains the Docker template XML file for installing **Gupax-docker** on [Unraid](https://unraid.net/) via the [Community Applications](https://forums.unraid.net/topic/38582-plug-in-community-applications/) plugin.

## How to Use

### Option 1: Community Applications (Recommended)

Once this template is merged into the [Unraid Docker Template Repository](https://github.com/selfhosters/unRAID-CA-templates), you can install Gupax-docker directly from the Unraid Apps tab:

1. Open **Apps** tab in Unraid
2. Search for **"gupax"** or **"monero mining"**
3. Click **Install**
4. Set your `WALLET_ADDRESS` in the template
5. Click **Apply** and start mining!

### Option 2: Manual Installation via Template URL

1. Go to **Docker** tab in Unraid
2. Click **Add Container**
3. Set **Template URL** to:
   ```
   https://raw.githubusercontent.com/w111a/Gupax-docker/main/templates/gupax-docker.xml
   ```
4. Fill in the required fields (especially `WALLET_ADDRESS`)
5. Click **Apply**

### Option 3: Add Repository to Community Applications

1. Go to **Apps** tab → **Settings** (gear icon)
2. In **Template repositories**, add:
   ```
   https://github.com/w111a/Gupax-docker
   ```
3. Refresh the Apps page
4. Search for **"gupax"** and install

## Configuration

| Field | Required | Default | Description |
|---|---|---|---|
| `WALLET_ADDRESS` | ✅ Yes | — | Your Monero wallet address for payouts |
| `P2POOL_MINI` | No | `true` | Use P2Pool mini sidechain (recommended) |
| `XMRIG_THREADS` | No | `0` | CPU mining threads (0 = auto) |
| `MONERO_NODE` | No | `auto` | Monero node: auto, local, or remote |
| P2Pool Stratum Port | No | `3333` | Port for miners to connect |
| P2Pool Monero Port | No | `37889` | P2Pool ZMQ port |

## Volumes

The template creates two persistent data directories under `/mnt/user/appdata/gupax-docker/`:

- `p2pool/` — P2Pool database and share data
- `monero/` — Monero blockchain data

## ⚠️ Important Notes

- **You MUST set `WALLET_ADDRESS` before starting the container** — it will fail without it.
- Mining cryptocurrency consumes significant electricity and may not be profitable.
- For best results on Unraid, consider setting `XMRIG_THREADS` to less than your total CPU cores to leave resources for other Docker containers.

## Submitting to Community Applications

To have this template included in the official Unraid Community Applications store, submit a PR to:

- [selfhosters/unRAID-CA-templates](https://github.com/selfhosters/unRAID-CA-templates)

Include the template XML file and the repository URL in your PR.

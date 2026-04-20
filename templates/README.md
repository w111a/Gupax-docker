# Unraid Docker Templates

This directory contains the Docker template XML file for installing **Gupax-docker** on [Unraid](https://unraid.net/) via the [Community Applications](https://forums.unraid.net/topic/38582-plug-in-community-applications/) plugin.

The Docker image is published to both:
- **Docker Hub**: [libre7/gupax-docker](https://hub.docker.com/r/libre7/gupax-docker) (recommended for Unraid)
- **GitHub Container Registry**: [ghcr.io/w111a/gupax-docker](https://github.com/w111a/Gupax-docker/pkgs/container/gupax-docker)

## How to Use

### Option 1: Community Applications (Recommended)

Once this template is merged into the [Unraid Docker Template Repository](https://github.com/selfhosters/unRAID-CA-templates), you can install Gupax-docker directly from the Unraid Apps tab:

1. Open **Apps** tab in Unraid
2. Search for **"gupax"** or **"monero mining"**
3. Click **Install**
4. Set SCREEN_RESOLUTION if needed (default: 1920x1080x24)
5. Click **Apply** and start mining!

### Option 2: Manual Installation via Template URL

1. Go to **Docker** tab in Unraid
2. Click **Add Container**
3. Set **Template URL** to:
   ```
   https://raw.githubusercontent.com/w111a/Gupax-docker/main/templates/gupax-docker.xml
   ```
4. Fill in fields as needed — no WALLET_ADDRESS required (set it in the Gupax GUI)
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
| `SCREEN_RESOLUTION` | No | `1920x1080x24` | Display resolution for Gupax GUI |

## Accessing the GUI

The container runs a **noVNC web interface** — no X11 or VNC client needed:

- Open your browser to: `http://<your-unraid-ip>:6080`
- Click **Connect** on the noVNC page — no password required by default
- The Gupax GUI will appear in your browser

## Ports

| Port | Service | Description |
| 6080 | noVNC | **Web interface** — connect your browser here |
| 5900 | VNC | Direct VNC access (optional) |
| 3333 | P2Pool | Stratum server for external miners |
| 37889 | P2Pool | Monero node ZMQ |
| 18080 | Monerod | Monero P2P network |
| 18081 | Monerod | Monero RPC |

## Volumes

The template creates two persistent directories under `/mnt/user/appdata/gupax/`:

- `config/` — Gupax configuration, wallet, and state
- `monero/` — Monero blockchain data

## Using an Existing Blockchain

If you already have a Monero blockchain synced:

1. Start the container once so the volume is created
2. Copy your blockchain to `/mnt/user/appdata/gupax/monero/`
3. In the Gupax GUI, go to the **Node tab** and set the database path to:
   ```
   /home/miner/.bitmonero
   ```

## Resource Limits

The template sets recommended limits of **4GB RAM** and **2 CPU cores**. Adjust these in the template if needed.

## Submitting to Community Applications

To have this template included in the official Unraid Community Applications store, submit a PR to:

- [selfhosters/unRAID-CA-templates](https://github.com/selfhosters/unRAID-CA-templates)

Include the template XML file and the repository URL in your PR.

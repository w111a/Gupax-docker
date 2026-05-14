# Unraid Docker Templates

This directory contains the Docker template XML file for installing **Gupax-docker** on [Unraid](https://unraid.net/) via the [Community Applications](https://forums.unraid.net/topic/38582-plug-in-community-applications/) plugin.

The Docker image is published to both:
- **Docker Hub**: [libre7/gupax-docker](https://hub.docker.com/r/libre7/gupax-docker) (recommended for Unraid)
- **GitHub Container Registry**: [ghcr.io/libre-7/gupax-docker](https://github.com/libre-7/Gupax-docker/pkgs/container/gupax-docker)

## How to Use

### Option 1: Community Applications (Recommended)

Once this template is merged into the [Unraid Docker Template Repository](https://github.com/selfhosters/unRAID-CA-templates), you can install Gupax-docker directly from the Unraid Apps tab:

1. Open **Apps** tab in Unraid
2. Search for **"gupax"** or **"monero mining"**
3. Click **Install**
4. Set SCREEN_RESOLUTION if needed (default: 1920x1080x24)
5. Click **Apply** and start mining!

### Option 2: Manual Installation

If the template is not yet in the Community Applications store, you can install it manually by placing the XML on your Unraid USB flash drive:

1. Download the template onto the flash drive:
   ```bash
   # From Unraid terminal:
   wget -O /boot/config/plugins/dockerMan/templates-user/my-gupax-docker.xml \
     https://raw.githubusercontent.com/libre-7/gupax-docker/main/templates/gupax-docker.xml
   ```
2. Go to the **Docker** tab in your Unraid web UI
3. Click **Add Container**
4. Select **"my-gupax-docker"** from the **Template** dropdown
5. Review settings (adjust SCREEN_RESOLUTION if needed) and click **Apply**

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
| 37889 | P2Pool | P2P — p2pool peer connections |
| 18080 | Monerod | Monero P2P network |
| 18081 | Monerod | Monero RPC |

## Volumes

The template creates four persistent directories under `/mnt/user/appdata/gupax/`:

- `config/` — Gupax configuration, wallet, and state
- `share/` — Downloaded mining binaries (P2Pool, XMRig, monerod)
- `monero/` — Monero blockchain data
- `tor/` — Tor hidden service keys (persists .onion address)

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

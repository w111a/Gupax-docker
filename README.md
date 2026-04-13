# Gupax-docker

Docker setup for [Gupax](https://github.com/hinto-janai/gupax) — a GUI for P2Pool & XMRig for Monero mining.

## Features

- 🐳 Easy Docker-based deployment
- ⛏️ Bundled P2Pool + XMRig via Gupax
- 🔒 Isolated environment for mining operations
- 🔄 Simple configuration and updates

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Quick Start

1. **Clone the repository:**

   ```bash
   git clone https://github.com/w111a/Gupax-docker.git
   cd Gupax-docker
   ```

2. **Build and start the container:**

   ```bash
   docker compose up -d
   ```

3. **Access Gupax:**

   Connect to the VNC client or X11 forwarding as configured.

## Configuration

Edit the `.env` file or environment variables in `docker-compose.yml` to customize:

| Variable        | Description                     | Default |
|-----------------|---------------------------------|---------|
| `P2POOL_MODE`   | P2Pool mining mode              | `node`  |
| `MONERO_ADDRESS`| Your Monero wallet address      | —       |
| `VNC_PASSWORD`  | Password for VNC access         | `gupax` |

## Usage

```bash
# Start in detached mode
docker compose up -d

# View logs
docker compose logs -f

# Stop
docker compose down

# Rebuild after changes
docker compose up -d --build
```

## Updating

```bash
git pull
docker compose up -d --build
```

## Troubleshooting

- **VNC not accessible:** Ensure the correct port is mapped and the VNC password is set.
- **Mining not starting:** Verify your Monero wallet address is configured.
- **Performance issues:** Adjust CPU/memory limits in `docker-compose.yml`.

## License

This project is licensed under the same license as [Gupax](https://github.com/hinto-janai/gupax).

## Acknowledgments

- [Gupax](https://github.com/hinto-janai/gupax) — The main Gupax project
- [P2Pool](https://github.com/SChernykh/p2pool) — Decentralized Monero mining pool
- [XMRig](https://github.com/xmrig/xmrig) — High-performance Monero miner

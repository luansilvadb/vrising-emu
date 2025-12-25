# 🧛 V Rising ARM64 Dedicated Server

[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://www.docker.com/)
[![ARM64](https://img.shields.io/badge/ARM64-Production-green?logo=arm)](https://www.arm.com/)
[![BepInEx](https://img.shields.io/badge/BepInEx-Supported-purple)](https://github.com/BepInEx/BepInEx)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

Production-ready V Rising dedicated server optimized for **ARM64** (Oracle Ampere, Raspberry Pi 5, etc.) with full **BepInEx** mod support.

---

## ✨ Features

- ✅ **ARM64 Native** - Optimized for Ampere/ARM64 CPUs
- ✅ **Box64/Box86** - Efficient x86/x64 emulation
- ✅ **Wine Staging** - With NTSync + WoW64 support
- ✅ **BepInEx** - Full mod framework with ARM64 patches
- ✅ **SteamCMD** - Automatic server updates
- ✅ **EasyPanel Ready** - One-click deploy via UI
- ✅ **Graceful Shutdown** - Proper autosave before stopping
- ✅ **Backup/Restore** - Built-in scripts for data management
- ✅ **Production Tested** - Based on tsx-cloud battle-tested configuration

---

## 🚀 Quick Start

### Option 1: Pre-built Image (RECOMMENDED)

The fastest way to get started - uses the production-tested tsx-cloud image:

```bash
# Clone repository
git clone https://github.com/YOUR_USER/vrising-emu.git
cd vrising-emu

# Start with pre-built image
docker compose -f docker-compose.easypanel.yml up -d

# View logs
docker compose -f docker-compose.easypanel.yml logs -f
```

### Option 2: Build from Source

Full control over the image with local Dockerfile:

```bash
# Build image (takes 20-40 minutes first time)
docker compose build

# Start server
docker compose up -d

# View logs
docker compose logs -f vrising
```

### Option 3: EasyPanel Deployment

1. Push this repository to GitHub
2. In EasyPanel: Create Project → Add Service → App
3. Select GitHub → Your Repository
4. Configure environment variables
5. Deploy! 🚀

---

## 📁 Project Structure

```
vrising-emu/
├── Dockerfile                          # Production multi-stage build
├── docker-compose.yml                  # Development (local build)
├── docker-compose.easypanel.yml        # Production (pre-built image)
├── entrypoint.sh                       # Main startup script
├── .dockerignore                       # Build optimization
├── .gitignore                          # Git ignore rules
├── .env.example                        # Environment template
├── README.md                           # This file
│
├── bepinex/
│   ├── doorstop_config.ini             # BepInEx loader config
│   ├── README.md                       # BepInEx ARM64 guide
│   └── addition_stuff/
│       └── box64.rc                    # Box64 optimization
│
├── config/
│   ├── ServerHostSettings.json         # Server configuration
│   └── ServerGameSettings.json         # Gameplay settings
│
├── docs/
│   ├── DEEP_RESEARCH_EASYPANEL_ARM64.md
│   └── MODS_GUIDE.md                   # KindredLogistics & more
│
└── scripts/
    ├── update-server.sh                # Update via SteamCMD
    ├── backup.sh                       # Backup save data
    ├── restore.sh                      # Restore from backup
    ├── status.sh                       # Server status check
    ├── healthcheck.sh                  # Docker health check
    └── install-bepinex.sh              # Install BepInEx
```

---

## ⚙️ Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `TZ` | Timezone | `UTC` |
| `SERVERNAME` | Server name | `V Rising Server` |
| `ENABLE_PLUGINS` | Enable BepInEx | `false` |
| `UPDATE_SERVER` | Update on start | `true` |
| `LOGDAYS` | Days to keep logs | `30` |

### Box64 Performance (ARM64)

| Variable | Description | Recommended |
|----------|-------------|-------------|
| `BOX64_DYNAREC` | Dynamic recompilation | `1` |
| `BOX64_DYNAREC_BIGBLOCK` | Compilation block size | `2` |
| `BOX64_DYNAREC_FASTROUND` | Fast FP rounding | `1` |
| `BOX64_DYNAREC_FASTNAN` | Fast NaN handling | `1` |
| `BOX64_DYNAREC_SAFEFLAGS` | Safety checks | `0` |
| `BOX64_DYNAREC_BLEEDING_EDGE` | Experimental opts | `1` |

See `.env.example` for complete list.

---

## 📁 Volumes

| Path | Description |
|------|-------------|
| `/mnt/vrising/server` | Server files (V Rising, Wine, BepInEx) |
| `/mnt/vrising/persistentdata` | Saves, configs, logs |

### Data Structure

```
persistentdata/
├── Settings/
│   ├── ServerHostSettings.json
│   └── ServerGameSettings.json
├── Saves/
│   └── world1/
└── logs/
    └── 20251225-1200-VRisingServer.log
```

---

## 🔌 Ports

| Port | Protocol | Description |
|------|----------|-------------|
| `9876` | UDP | Game port (required) |
| `9877` | UDP | Query port (server browser) |
| `25575` | TCP | RCON (remote admin) |
| `9090` | TCP | API/Metrics (Prometheus) |

---

## 🔧 BepInEx & Mods

### Enable Plugins

```yaml
environment:
  - ENABLE_PLUGINS=true
```

### Install Mods

1. Place `.dll` files in:
   ```
   /mnt/vrising/server/BepInEx/plugins/
   ```
2. Restart server

### 🏭 Featured Mod: KindredLogistics

Transform your castle into an automated industrial machine:

| Feature | Description |
|---------|-------------|
| **Quick Stash** | Auto-deposit items into matching chests |
| **Craft from Containers** | Stations pull from nearby chests |
| **Auto-Salvage** | Dump chest → Devourer |
| **Auto-Refill** | Keep braziers/tombs supplied |

📖 **Full Guide**: [docs/MODS_GUIDE.md](docs/MODS_GUIDE.md)

---

## 🛠️ Management Commands

```bash
# View logs
docker compose logs -f vrising

# Server status
docker exec vrising /opt/scripts/status.sh

# Manual update
docker exec vrising /opt/scripts/update-server.sh validate

# Create backup
docker exec vrising /opt/scripts/backup.sh

# Restore backup
docker exec vrising /opt/scripts/restore.sh vrising-backup-20251225.tar.gz

# Restart server (graceful)
docker compose restart vrising

# Shell access
docker exec -it vrising bash
```

---

## 📊 Hardware Requirements

### Minimum

| Resource | Requirement |
|----------|-------------|
| CPU | 4 cores ARM64 @ 2.5GHz |
| RAM | 8GB |
| Disk | 15GB SSD |
| Network | 10 Mbps |

### Recommended (Your Setup)

| Resource | Specification |
|----------|---------------|
| CPU | 4 cores Ampere @ 3GHz |
| RAM | 24GB |
| Disk | 25GB+ SSD |
| Network | 100 Mbps |

### Container Limits

```yaml
deploy:
  resources:
    limits:
      cpus: '3.5'      # Leave 0.5 for system
      memory: 18G      # Leave 6G for system
```

---

## ⚡ NTSync Performance

For Ubuntu 25.04+ with kernel 6.14+:

```bash
# Check if available
ls /dev/ntsync

# Enable in docker-compose
devices:
  - /dev/ntsync:/dev/ntsync
```

Performance boost: **20-600%** for multithreaded operations!

---

## 🐛 Troubleshooting

### Server won't start

```bash
# Check logs
docker compose logs vrising | tail -100

# Check disk space
docker exec vrising df -h

# Check server status
docker exec vrising /opt/scripts/status.sh
```

### BepInEx not loading

```bash
# Check doorstop config
docker exec vrising cat /mnt/vrising/server/doorstop_config.ini

# Check BepInEx logs
docker exec vrising cat /mnt/vrising/server/BepInEx/LogOutput.log
```

### SteamCMD fails

```bash
# Check disk space (need ~15GB)
docker exec vrising df -h

# Manual update
docker exec vrising /opt/scripts/update-server.sh validate
```

### High memory usage

```bash
# Check memory
docker stats vrising

# Restart Wine
docker exec vrising wineserver -k
docker compose restart vrising
```

---

## 📚 Documentation

- [Deep Research - EasyPanel ARM64](docs/DEEP_RESEARCH_EASYPANEL_ARM64.md)
- [Mods Guide - KindredLogistics](docs/MODS_GUIDE.md)
- [BepInEx ARM64 Setup](bepinex/README.md)

### External Resources

- [tsx-cloud/vrising-ntsync](https://github.com/tsx-cloud/vrising-ntsync)
- [Box64 Documentation](https://github.com/ptitSeb/box64/blob/main/docs/USAGE.md)
- [V Rising Mods (Thunderstore)](https://v-rising.thunderstore.io/)
- [Kron4ek Wine Builds](https://github.com/Kron4ek/Wine-Builds)

---

## 📝 License

MIT License - See [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- [tsx-cloud](https://github.com/tsx-cloud) - Production Docker image & ARM64 patches
- [TrueOsiris](https://github.com/TrueOsiris) - Original Docker implementation
- [ptitSeb](https://github.com/ptitSeb) - Box64/Box86 emulation
- [Kron4ek](https://github.com/Kron4ek) - Wine Staging builds
- [BepInEx Team](https://github.com/BepInEx) - Modding framework

---

<div align="center">

**⭐ Star this repo if it helped you! ⭐**

Made with 🧛 for the V Rising community

</div>

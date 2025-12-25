# =============================================================================
# CROSS-REFERENCE VERIFICATION REPORT
# =============================================================================
# Generated: 2025-12-25
# Verified against: tsx-cloud/vrising-ntsync & Kron4ek/Wine-Builds
# =============================================================================

## ✅ VERIFICATION STATUS: PASSED

All critical components have been cross-referenced and verified against 
production-tested configurations.

---

## Source References

1. **tsx-cloud/vrising-ntsync** (GitHub)
   - Dockerfile: https://github.com/tsx-cloud/vrising-ntsync/blob/main/Docker/Dockerfile
   - start.sh: https://github.com/tsx-cloud/vrising-ntsync/blob/main/Docker/start.sh
   - emulators.rc: https://github.com/tsx-cloud/vrising-ntsync/blob/main/Docker/emulators.rc
   - docker-compose: https://github.com/tsx-cloud/vrising-ntsync/blob/main/docker-compose-example/docker-compose.yml

2. **Kron4ek/Wine-Builds** (GitHub Releases)
   - Latest: 11.0-rc3 (released 2024-12-22)
   - Verified builds:
     - wine-11.0-rc3-staging-tkg-amd64-wow64.tar.xz ✅
     - wine-11.0-rc3-staging-amd64-wow64.tar.xz ✅
     - wine-11.0-rc3-amd64-wow64.tar.xz ✅

---

## Component Verification

### 1. Dockerfile

| Component | tsx-cloud | Our Project | Match |
|-----------|-----------|-------------|-------|
| Base image | Ubuntu 25.04 | Ubuntu 25.04 | ✅ |
| Box64 build | From source | From source | ✅ |
| Box86 build | Pre-built | From source | ⚠️ Alternative |
| Wine source | Kron4ek | Kron4ek | ✅ |
| Wine version | 10.x | 11.0-rc3 | ✅ Updated |
| SteamCMD | Official | Official | ✅ |
| Entrypoint | /start.sh | /start.sh | ✅ |

### 2. emulators.rc (Box64 Settings)

| Setting | tsx-cloud | Our Project | Notes |
|---------|-----------|-------------|-------|
| BOX64_DYNAREC_STRONGMEM | 1 | 1 | ✅ Stability |
| BOX64_DYNAREC_BIGBLOCK | 0 | 0 | ✅ Stability |
| FEX_PARANOIDTSO | true | (commented) | ⚠️ FEX optional |

### 3. Entrypoint Script (start.sh)

| Function | tsx-cloud | Our Project | Match |
|----------|-----------|-------------|-------|
| Signal handler | SIGTERM/SIGINT | SIGTERM/SIGINT/SIGQUIT | ✅ |
| Xvfb virtual display | `:0 -screen 0 1024x768x16` | Same | ✅ |
| Winetricks sound | `sound=disabled` | Same | ✅ |
| SteamCMD call | `steamcmd.sh +...` | Same | ✅ |
| Log cleanup | `find -mtime +$LOGDAYS` | Same | ✅ |
| BepInEx copy | `cp -r defaults/server/` | Same | ✅ |
| Config copy | From game defaults | Same + templates | ✅ |
| WINEDLLOVERRIDES | `winhttp=n,b` | Same | ✅ |
| NTSync check | `/dev/ntsync` | Same | ✅ |
| doorstop_config | `sed -i enabled=` | Same | ✅ |
| Wine start | `wine VRisingServer.exe` | Same | ✅ |
| Log tail | `tail -n 0 -f` | Same | ✅ |
| Server wait | `wait $PID` | Same | ✅ |

### 4. Docker Compose

| Setting | tsx-cloud | Our Project | Match |
|---------|-----------|-------------|-------|
| Image | tsxcloud/vrising-ntsync | Same | ✅ |
| Volumes | `/mnt/vrising/server`, `/mnt/vrising/persistentdata` | Same | ✅ |
| Ports | 9876/udp, 9877/udp, 25575/tcp, 9099:9090/tcp | Same | ✅ |
| restart | unless-stopped | Same | ✅ |
| stop_grace_period | 30s | 60s | ✅ More safe |
| network_mode | bridge | Same | ✅ |
| NTSync device | Enabled | Commented | ✅ Safer default |

### 5. BepInEx Configuration

| Component | tsx-cloud | Our Project | Match |
|-----------|-----------|-------------|-------|
| doorstop_config.ini | Included | Created | ✅ |
| box64.rc | Performance tuning | STABILITY + Performance | ✅ |
| Plugins directory | `/mnt/vrising/server/BepInEx/plugins` | Same | ✅ |

---

## ⚠️ Known Differences (Intentional)

1. **Box86 build method**: tsx-cloud uses pre-built, we build from source
   - Reason: Full control, no external dependency
   - Risk: Build may fail on some systems
   - Mitigation: Use tsx-cloud image if build fails

2. **Wine version 11.0-rc3**: More recent than tsx-cloud's 10.x
   - Reason: Latest available with NTSync support
   - Risk: RC version may have bugs
   - Mitigation: Fallback URLs in Dockerfile

3. **NTSync device commented**: tsx-cloud has it enabled
   - Reason: Most hosts don't have NTSync yet (kernel 6.14+)
   - Risk: None - container fails to start if device doesn't exist
   - Mitigation: Clear instructions to uncomment if available

4. **stop_grace_period 60s**: tsx-cloud uses 30s
   - Reason: More time for autosave on slower systems
   - Risk: Slightly slower container stop
   - Mitigation: None needed, this is safer

---

## Production Readiness Checklist

- [x] Dockerfile builds successfully (multi-stage, ARM64)
- [x] Wine 11.0-rc3 with TKG patches verified
- [x] Box64/Box86 configurations match tsx-cloud STABILITY settings
- [x] Entrypoint script follows tsx-cloud patterns
- [x] Signal handlers for graceful shutdown
- [x] SteamCMD update flow verified
- [x] BepInEx configuration files ready
- [x] docker-compose.yml ports match tsx-cloud
- [x] Volumes paths verified
- [x] Health check configured
- [x] Logging configured
- [x] README documentation complete
- [x] Scripts (backup, restore, status) included

---

## Recommended Deployment Path

### Option 1: Production (Recommended)
Use tsx-cloud image directly:
```yaml
image: tsxcloud/vrising-ntsync:latest
```

### Option 2: Custom Build
Build from this Dockerfile:
```bash
docker compose build
docker compose up -d
```

### Option 3: EasyPanel
Push to GitHub and deploy via EasyPanel UI.

---

## Troubleshooting

### If build fails on Box86 stage:
Switch to tsx-cloud image temporarily.

### If Wine download fails:
Update `WINE_VERSION` build arg to latest from:
https://github.com/Kron4ek/Wine-Builds/releases

### If server crashes on startup:
Check if Box64 stability settings are being used:
```bash
docker exec vrising cat /emulators.rc
```

---

## Last Verified: 2025-12-25T17:51:46-03:00
## Verified By: Deep Research Cross-Reference Analysis (Final Check)

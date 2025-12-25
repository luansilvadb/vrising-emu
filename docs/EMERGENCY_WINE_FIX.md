# Emergency Wine Fix - Deployment Guide

## Problem Summary
Wine was failing with `could not load ntdll.so` error due to hardcoded library paths in the wrapper scripts that didn't match the actual Wine directory structure.

## What Was Fixed
1. **Dockerfile (lines 225-265)**: Wine wrapper scripts now dynamically detect library paths instead of using hardcoded `/opt/wine/lib/wine/x86_64-unix`
2. **entrypoint.sh (lines 116-131)**: Added fail-fast logic to prevent infinite loops when Wine is broken

## Deployment Steps

### Step 1: Stop Current Container
SSH to your Oracle Cloud server:
```bash
ssh ubuntu@<your-server-ip>
```

Stop the looping container:
```bash
cd /path/to/vrising-emu
docker-compose down
# Or force stop if needed:
docker stop vrising-arm64
docker rm vrising-arm64
```

### Step 2: Pull Updated Code
On your Oracle Cloud server:
```bash
cd /path/to/vrising-emu
git pull origin main
# Or manually copy Dockerfile and entrypoint.sh from your local machine
```

### Step 3: Rebuild Image
```bash
# Clean build to ensure Wine wrappers are recreated
docker-compose build --no-cache runtime

# This will take 20-40 minutes on first build
```

**Watch the build output** for these key messages:
```
Wine lib directories:
  Unix libs: <actual-path>/x86_64-unix
  Base libs: <actual-path>
Wine 11.0-rc3 installed and wrappers created successfully
```

### Step 4: Start Server
```bash
docker-compose up -d
```

### Step 5: Verify Wine Works
```bash
# Check logs
docker-compose logs -f

# Should see:
# Wine: wine-11.0-rc3
# (No ntdll.so error!)
```

### Step 6: Test Wine Manually (Optional)
```bash
docker exec -it vrising-arm64 bash
wine --version
# Should output: wine-11.0-rc3
```

## Expected Timeline
- Build: 20-40 minutes (first time)
- Server download: 5-10 minutes (SteamCMD)
- Total: 30-50 minutes to running server

## If Build Fails
Check build logs for:
```
Found wine binary at: /opt/wine/bin/wine64
Wine bin directory: /opt/wine/bin
Wine lib directories:
  Unix libs: /opt/wine/lib/wine/x86_64-unix
  Base libs: /opt/wine/lib/wine
```

If these paths don't appear, the Wine download failed. Retry build.

## Monitoring
After startup, monitor:
```bash
# Real-time logs
docker-compose logs -f

# Check server process
docker exec vrising-arm64 pgrep -a VRisingServer

# Check Wine prefix
docker exec vrising-arm64 ls -la /root/.wine
```

## Success Indicators
✅ No `ntdll.so` error in logs
✅ Wine version displays correctly
✅ SteamCMD updates server files
✅ `VRisingServer.exe` process starts
✅ Server listens on port 9876/udp

## Rollback Plan
If this fix doesn't work:
```bash
docker-compose down
git checkout HEAD~1
docker-compose build --no-cache
docker-compose up -d
```

## Next Steps After Success
1. Configure server settings in `config/ServerHostSettings.json`
2. Set server name via `.env`: `SERVERNAME="Your Server Name"`
3. Enable plugins (if needed): `ENABLE_PLUGINS=true`
4. Open firewall ports: 9876/udp, 9877/udp

## Support
If you still see Wine errors:
1. Share build logs: `docker-compose build --no-cache 2>&1 | tee build.log`
2. Share runtime logs: `docker-compose logs > runtime.log`
3. Share Wine wrapper: `docker exec vrising-arm64 cat /usr/local/bin/wine`

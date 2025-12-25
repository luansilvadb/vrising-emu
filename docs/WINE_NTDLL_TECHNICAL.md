# Wine ntdll.so Loading Failure - Technical Analysis

## Root Cause
The Wine wrapper scripts in `/usr/local/bin/wine*` were using **hardcoded library paths**:
```bash
export BOX64_LD_LIBRARY_PATH="/opt/wine/lib/wine/x86_64-unix:/opt/wine/lib:$BOX64_LD_LIBRARY_PATH"
```

However, the actual Wine directory structure after extraction varied depending on the Wine build variant:
- `wine-11.0-rc3-staging-tkg-amd64-wow64.tar.xz` extracts to different paths than
- `wine-11.0-rc3-staging-amd64-wow64.tar.xz` which differs from
- `wine-11.0-rc3-amd64-wow64.tar.xz`

## Why It Failed
Box64 couldn't find `ntdll.so` because:
1. Wine binary path: `/opt/wine/bin/wine64` ✅ (found via dynamic search)
2. Library path: `/opt/wine/lib/wine/x86_64-unix` ❌ (hardcoded, wrong)
3. Actual path: `/opt/wine/lib64/wine/x86_64-unix` or similar ⚠️

When Box64 tried to execute Wine, it couldn't load the core NT compatibility layer.

## The Fix
**Dynamic path detection in Dockerfile:**
```bash
# Find actual Wine library paths
WINE_LIB_UNIX=$(find ${WINE_PATH} -type d -path "*/lib*/wine/x86_64-unix" 2>/dev/null | head -1)
WINE_LIB_BASE=$(dirname "$WINE_LIB_UNIX" 2>/dev/null)

# Use detected paths in wrappers
echo "export BOX64_LD_LIBRARY_PATH=\"$WINE_LIB_UNIX:$WINE_LIB_BASE:\$BOX64_LD_LIBRARY_PATH\""
```

This ensures the wrapper scripts point to the **actual** Wine library locations, regardless of the Wine build variant.

## Technical Deep Dive

### Wine on ARM64 Architecture
```
┌─────────────────────────────────────┐
│   V Rising Server (x86_64 .exe)    │
│                                     │
│   ┌─────────────────────────────┐  │
│   │      Wine (x86_64)          │  │ ← Needs ntdll.so
│   │  ┌─────────────────────┐    │  │
│   │  │  Box64 Emulator     │    │  │
│   │  │  (ARM64 native)     │    │  │
│   │  └─────────────────────┘    │  │
│   └─────────────────────────────┘  │
│                                     │
│   Linux ARM64 Kernel                │
└─────────────────────────────────────┘
```

### Library Loading Process
1. **entrypoint.sh** calls `wine --version`
2. `/usr/local/bin/wine` wrapper script executes:
   ```bash
   export BOX64_LD_LIBRARY_PATH="<paths>"
   exec box64 /opt/wine/bin/wine64 "$@"
   ```
3. **Box64** starts emulating `/opt/wine/bin/wine64`
4. **Wine** tries to load `ntdll.so` from `BOX64_LD_LIBRARY_PATH`
5. If path is wrong → ❌ `Cannot dlopen(...ntdll.so)`
6. If path is correct → ✅ Wine initializes

### BOX64_LD_LIBRARY_PATH Importance
This environment variable tells Box64 where to find x86_64 libraries for emulated binaries.

**Without it:**
- Box64 only searches standard Linux paths (`/lib`, `/usr/lib`)
- Wine libraries are in `/opt/wine/lib*/wine/`
- Result: `ntdll.so` not found

**With correct path:**
- Box64 searches Wine's library directories first
- Finds `ntdll.so`, `kernel32.dll.so`, etc.
- Wine loads successfully

## Verification Commands

### Check Wine wrapper configuration:
```bash
docker exec vrising-arm64 cat /usr/local/bin/wine
```

Expected output:
```bash
#!/bin/bash
export BOX64_LD_LIBRARY_PATH="/opt/wine/lib/wine/x86_64-unix:/opt/wine/lib/wine:$BOX64_LD_LIBRARY_PATH"
exec box64 /opt/wine/bin/wine64 "$@"
```

### Check actual Wine library structure:
```bash
docker exec vrising-arm64 find /opt/wine -name "ntdll.so" -type f
```

Expected output:
```
/opt/wine/lib/wine/x86_64-unix/ntdll.so
```

### Test Wine manually:
```bash
docker exec vrising-arm64 bash -c 'export BOX64_LOG=1 && wine --version'
```

Look for:
```
Allocate a new mmap for 0x<address>
...
wine-11.0-rc3
```

If you see `Error: Cannot dlopen`, the paths are still wrong.

## Related Issues

### Issue 1: SteamCMD infinite loop
**Symptom:** Container restarts every ~18 seconds
**Cause:** Wine fails → entrypoint continues → tries to start server → fails → Docker restarts
**Fix:** Added fail-fast in `entrypoint.sh` to exit on Wine errors

### Issue 2: Build cache prevents fix
**Symptom:** Rebuild doesn't fix Wine paths
**Cause:** Docker layer caching reuses old Wine wrapper scripts
**Fix:** Use `--no-cache` flag: `docker-compose build --no-cache`

### Issue 3: binfmt_misc warnings
**Symptom:** `binfmt_misc not available` warnings
**Cause:** Docker container lacks `/proc/sys/fs/binfmt_misc` access
**Impact:** NONE - wrapper scripts explicitly call Box64, don't need binfmt
**Action:** Ignore these warnings

## Prevention for Future

### For maintainers:
1. **Never hardcode paths** - always use dynamic detection
2. **Test multiple Wine variants** before releasing
3. **Add build verification** step to check Wine wrappers
4. **Document Wine version** changes in CHANGELOG

### For users:
1. Always rebuild with `--no-cache` after Dockerfile changes
2. Check Wine version output during build
3. Verify `wine --version` works before starting server
4. Keep Wine version locked in `ARG WINE_VERSION=11.0-rc3`

## Additional Resources
- Wine on ARM64: https://wiki.winehq.org/ARM64
- Box64 documentation: https://github.com/ptitSeb/box64
- tsx-cloud reference: https://github.com/tsx-cloud/vrising-ntsync

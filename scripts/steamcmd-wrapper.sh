#!/bin/bash
# =============================================================================
# SteamCMD Wrapper Script for ARM64
# =============================================================================
# This wrapper ensures SteamCMD runs correctly under Box86 on ARM64 systems
# SteamCMD is 32-bit, so it needs Box86 (not Box64)
# Usage: steamcmd-wrapper.sh [steamcmd arguments]

set -e

STEAMCMD_DIR="${STEAMCMD_PATH:-/opt/steamcmd}"
STEAMCMD_SH="${STEAMCMD_DIR}/steamcmd.sh"
STEAMCMD_BIN="${STEAMCMD_DIR}/linux32/steamcmd"

# Check if running on ARM64
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    # Running on ARM64 - configure Box86 for SteamCMD
    export BOX86_NOBANNER=1
    export BOX86_LOG=0
    export BOX86_LD_LIBRARY_PATH="${STEAMCMD_DIR}/linux32"
    
    # Disable some Box86 features that can cause issues with SteamCMD
    export BOX86_DYNAREC_STRONGMEM=1
    export BOX86_DYNAREC_SAFEFLAGS=1
    
    if command -v box86 &> /dev/null; then
        cd "${STEAMCMD_DIR}"
        exec "$STEAMCMD_SH" "$@"
    else
        echo "Error: Box86 not found. Cannot run SteamCMD on ARM64."
        exit 1
    fi
else
    # Running on x86/x86_64 - run SteamCMD directly
    cd "${STEAMCMD_DIR}"
    exec "$STEAMCMD_SH" "$@"
fi

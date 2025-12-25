#!/bin/bash
# =============================================================================
# Wine Wrapper Script for ARM64
# =============================================================================
# This wrapper ensures Wine runs correctly under Box64 on ARM64 systems
# Usage: wine-wrapper.sh [wine arguments]

set -e

# Determine which Wine to use
WINE_BIN="${WINE_PATH:-/opt/wine}/bin/wine64"

# Check if running on ARM64
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    # Running on ARM64 - use Box64
    if command -v box64 &> /dev/null; then
        exec box64 "$WINE_BIN" "$@"
    else
        echo "Error: Box64 not found. Cannot run Wine on ARM64."
        exit 1
    fi
else
    # Running on x86_64 - run Wine directly
    exec "$WINE_BIN" "$@"
fi

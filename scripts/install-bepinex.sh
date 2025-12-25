#!/bin/bash
# =============================================================================
# Install BepInEx Script
# =============================================================================
# Installs or updates BepInEx in the V Rising server directory
# Usage: install-bepinex.sh [--force]

set -e

SERVER_DIR="${SERVER_PATH:-/mnt/vrising/server}"
BEPINEX_DIR="${SERVER_DIR}/BepInEx"
FORCE=false

if [ "$1" = "--force" ]; then
    FORCE=true
fi

# BepInEx version for V Rising (IL2CPP)
BEPINEX_VERSION="6.0.0-be.752"
BEPINEX_URL="https://github.com/BepInEx/BepInEx/releases/download/v${BEPINEX_VERSION}/BepInEx-Unity.IL2CPP-win-x64-${BEPINEX_VERSION}.zip"

# Check if already installed
if [ -f "${BEPINEX_DIR}/core/BepInEx.Core.dll" ] && [ "$FORCE" = false ]; then
    echo "BepInEx is already installed. Use --force to reinstall."
    exit 0
fi

echo "Installing BepInEx ${BEPINEX_VERSION}..."

# Backup existing config if present
if [ -d "${BEPINEX_DIR}/config" ]; then
    echo "Backing up existing config..."
    cp -r "${BEPINEX_DIR}/config" /tmp/bepinex-config-backup
fi

# Download and extract
cd /tmp
wget -q "${BEPINEX_URL}" -O bepinex.zip
echo "Extracting BepInEx..."
unzip -o bepinex.zip -d "${SERVER_DIR}/"
rm bepinex.zip

# Restore config
if [ -d /tmp/bepinex-config-backup ]; then
    echo "Restoring config backup..."
    cp -r /tmp/bepinex-config-backup/* "${BEPINEX_DIR}/config/" 2>/dev/null || true
    rm -rf /tmp/bepinex-config-backup
fi

# Create additional directories
mkdir -p "${BEPINEX_DIR}/plugins"
mkdir -p "${BEPINEX_DIR}/config"
mkdir -p "${BEPINEX_DIR}/patchers"
mkdir -p "${BEPINEX_DIR}/addition_stuff"

# Create Box64 config for BepInEx
cat > "${BEPINEX_DIR}/addition_stuff/box64.rc" << 'EOF'
# Box64 configuration for V Rising with BepInEx
# See: https://github.com/ptitSeb/box64/blob/main/docs/USAGE.md

[VRisingServer.exe]
BOX64_DYNAREC=1
BOX64_DYNAREC_BIGBLOCK=2
BOX64_DYNAREC_FASTROUND=1
BOX64_DYNAREC_FASTNAN=1
BOX64_DYNAREC_SAFEFLAGS=0
BOX64_DYNAREC_BLEEDING_EDGE=1
BOX64_MALLOC_HACK=1
BOX64_DYNAREC_STRONGMEM=0
EOF

echo "BepInEx ${BEPINEX_VERSION} installed successfully!"
echo "Plugins directory: ${BEPINEX_DIR}/plugins"
echo "Config directory: ${BEPINEX_DIR}/config"

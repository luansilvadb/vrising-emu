#!/bin/bash
# =============================================================================
# Update V Rising Server Script
# =============================================================================
# Can be run inside container to update the server
# Usage: update-server.sh [validate]

set -e

STEAMCMD_DIR="${STEAMCMD_PATH:-/opt/steamcmd}"
SERVER_DIR="${SERVER_PATH:-/mnt/vrising/server}"
STEAM_APP_ID=1829350

VALIDATE=""
if [ "$1" = "validate" ]; then
    VALIDATE="validate"
fi

echo "Updating V Rising server..."
echo "Server directory: ${SERVER_DIR}"
echo "Validate: ${VALIDATE:-no}"

cd "${STEAMCMD_DIR}"

./steamcmd.sh \
    +@sSteamCmdForcePlatformType windows \
    +force_install_dir "${SERVER_DIR}" \
    +login anonymous \
    +app_update ${STEAM_APP_ID} ${VALIDATE} \
    +quit

if [ $? -eq 0 ]; then
    echo "Server updated successfully!"
else
    echo "Warning: SteamCMD returned non-zero exit code"
    exit 1
fi

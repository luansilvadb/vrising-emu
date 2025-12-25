#!/bin/bash
# =============================================================================
# Update V Rising Server via SteamCMD
# =============================================================================
# Run inside container: docker exec vrising /opt/scripts/update-server.sh
# Options:
#   validate - Force validation of all files
#   beta <branch> - Switch to beta branch
# =============================================================================

set -e

SERVER_DIR="${SERVER_PATH:-/mnt/vrising/server}"
STEAM_APP_ID=1829350

# Parse arguments
VALIDATE=""
BETA_BRANCH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        validate)
            VALIDATE="validate"
            shift
            ;;
        beta)
            BETA_BRANCH="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: update-server.sh [validate] [beta <branch>]"
            exit 1
            ;;
    esac
done

echo "=============================================="
echo "V Rising Server Update"
echo "=============================================="
echo "Server directory: ${SERVER_DIR}"
echo "Validate: ${VALIDATE:-no}"
echo "Beta branch: ${BETA_BRANCH:-none}"
echo ""

# Build SteamCMD command
STEAM_CMD="steamcmd.sh +@sSteamCmdForcePlatformType windows +force_install_dir \"${SERVER_DIR}\" +login anonymous"

if [ -n "$BETA_BRANCH" ]; then
    STEAM_CMD="$STEAM_CMD +app_update ${STEAM_APP_ID} -beta ${BETA_BRANCH} ${VALIDATE}"
else
    STEAM_CMD="$STEAM_CMD +app_update ${STEAM_APP_ID} ${VALIDATE}"
fi

STEAM_CMD="$STEAM_CMD +quit"

# Run update
eval $STEAM_CMD

if [ $? -eq 0 ]; then
    echo ""
    echo "[OK] Server updated successfully!"
    if [ -f "${SERVER_DIR}/steam_appid.txt" ]; then
        echo "App ID: $(cat "${SERVER_DIR}/steam_appid.txt")"
    fi
else
    echo ""
    echo "[WARN] SteamCMD returned non-zero exit code"
    exit 1
fi

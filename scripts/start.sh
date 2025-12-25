#!/bin/bash
set -e

# Configuration
APP_ID=1829350
SERVER_DIR="/data/server"
STEAMCMD_ORIG="/steamcmd"
STEAMCMD_DIR="/data/steamcmd"
WINE_BIN="/opt/wine/bin/wine64"
XJUPITER_OPTS=""

echo ">>> V Rising Server with FEX-Emu + Wine (ARM64) <<<"

# Create directories
mkdir -p "$SERVER_DIR"
mkdir -p "$WINEPREFIX"

# Persist SteamCMD to avoid update loops
if [ ! -d "$STEAMCMD_DIR" ]; then
    echo ">>> Initializing persistent SteamCMD..."
    cp -r "$STEAMCMD_ORIG" "$STEAMCMD_DIR"
fi

# Update/Install Server
echo ">>> Checking for updates..."

if [ -f "$STEAMCMD_DIR/steamcmd.sh" ]; then
    echo ">>> Starting SteamCMD..."
    
    # Check for FEX presence
    if command -v FEXInterpreter >/dev/null; then
        WRAPPER="FEXInterpreter"
    else
        echo "Error: FEXInterpreter not found!"
        exit 1
    fi

    # Update Game
    # We allow steamcmd to fail/restart (it often returns error codes on self-update)
    # We loop it a few times to ensure it stabilizes.
    
    MAX_RETRIES=10
    i=0
    while [ $i -lt $MAX_RETRIES ]; do
        echo ">>> SteamCMD Attempt $(($i + 1))..."
        pushd "$STEAMCMD_DIR" > /dev/null
        
        # Clean appcache to prevent "Missing configuration" errors
        rm -rf appcache
        
        # Disable set -e for this command
        set +e
        $WRAPPER ./linux32/steamcmd \
            +@sSteamCmdForcePlatformType windows \
            +force_install_dir "$SERVER_DIR" \
            +login anonymous \
            +app_update $APP_ID validate \
            +quit
        EXIT_CODE=$?
        set -e
        
        popd > /dev/null
        
        if [ $EXIT_CODE -eq 0 ]; then
            echo ">>> SteamCMD finished successfully."
            break
        elif [ $EXIT_CODE -eq 7 ]; then
             echo ">>> SteamCMD is restarting..."
        elif [ $EXIT_CODE -eq 42 ]; then
             echo ">>> SteamCMD needs to restart (self-update)..."
        else
             echo ">>> SteamCMD exited with code $EXIT_CODE. Retrying..."
        fi
        
        i=$(($i + 1))
        sleep 5
    done
    
    if [ ! -f "$SERVER_DIR/VRisingServer.exe" ]; then
        echo "FATAL: VRisingServer.exe not found after SteamCMD update!"
        echo "Directory content of $SERVER_DIR:"
        ls -la "$SERVER_DIR" || true
        exit 1
    fi
else
    echo "Error: SteamCMD not found at $STEAMCMD_DIR"
    exit 1
fi

# BepInEx Setup
if [ "$ENABLE_BEPINEX" = "true" ]; then
    echo ">>> Setting up BepInEx..."
    # Previous URL logic is fine, but ensure it's robust
    BEPINEX_VERSION="6.0.0-be.668" 
    BEPINEX_URL="https://github.com/BepInEx/BepInEx/releases/download/v${BEPINEX_VERSION}/BepInEx_UnityIL2CPP_x64_${BEPINEX_VERSION}.zip"
    
    # Only download if missing core
    if [ ! -d "$SERVER_DIR/BepInEx/core" ]; then
        echo "Downloading BepInEx..."
        curl -L -o bepinex.zip "$BEPINEX_URL"
        unzip -o bepinex.zip -d "$SERVER_DIR"
        rm bepinex.zip
    fi
    
    # BepInEx Override (Environment)
    export WINEDLLOVERRIDES="winhttp=n,b"
    export DOORSTOP_ENABLE=TRUE
    export DOORSTOP_TARGET_ASSEMBLY="$SERVER_DIR/BepInEx/core/BepInEx.IL2CPP.dll"
    
    echo "BepInEx enabled."
fi

# Start Xvfb
echo ">>> Starting Xvfb..."
rm -f /tmp/.X0-lock
Xvfb :0 -screen 0 1024x768x16 &
sleep 2

# Wine Configuration
echo ">>> Configuring Wine..."
export WINEPREFIX="/data/wineprefix"
# Ensure simple non-interactive setup
export WINEDLLOVERRIDES="mscoree,mshtml=;winhttp=n,b" 

# Ensure wine boot runs once to create prefix
if [ ! -d "$WINEPREFIX/drive_c" ]; then
    echo "Booting Wine prefix..."
    # We ignore exit code of wineboot as it might print fixmes
    set +e
    FEXInterpreter "$WINE_BIN" wineboot --init
    set -e
fi

# Launch Server
echo ">>> Starting V Rising Dedicated Server..."
cd "$SERVER_DIR"

LAUNCH_CMD="VRisingServer.exe -batchmode -nographics -persistentDataPath Z:/data/save-data -serverName '${SERVER_NAME:-V Rising FEX}' -saveName '${SAVE_NAME:-world1}' -logFile Z:/data/VRisingServer.log -gamePort ${GAME_PORT:-9876} -queryPort ${QUERY_PORT:-9877}"

echo "Command: $LAUNCH_CMD"
exec FEXInterpreter "$WINE_BIN" $LAUNCH_CMD

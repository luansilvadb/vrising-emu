#!/bin/bash
# =============================================================================
# V Rising ARM64 Server - Entrypoint Script
# =============================================================================
set -e

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# -----------------------------------------------------------------------------
# Signal handling for graceful shutdown
# -----------------------------------------------------------------------------
shutdown_server() {
    log_warning "Shutdown signal received. Saving and stopping server..."
    
    # Send stop command to Wine/VRising
    if [ -n "$VRISING_PID" ]; then
        kill -SIGTERM "$VRISING_PID" 2>/dev/null || true
        
        # Wait for graceful shutdown
        local count=0
        while kill -0 "$VRISING_PID" 2>/dev/null && [ $count -lt 60 ]; do
            log_info "Waiting for server to save... ($count/60s)"
            sleep 1
            ((count++))
        done
        
        if kill -0 "$VRISING_PID" 2>/dev/null; then
            log_warning "Server didn't stop gracefully, forcing..."
            kill -SIGKILL "$VRISING_PID" 2>/dev/null || true
        fi
    fi
    
    # Stop wineserver
    wineserver -k 2>/dev/null || true
    
    log_success "Server stopped."
    exit 0
}

trap shutdown_server SIGTERM SIGINT SIGQUIT

# -----------------------------------------------------------------------------
# Environment Setup
# -----------------------------------------------------------------------------
log_info "=============================================="
log_info "V Rising ARM64 Server - Starting"
log_info "=============================================="
log_info "Server Name: ${SERVERNAME}"
log_info "Plugins Enabled: ${ENABLE_PLUGINS}"
log_info "Timezone: ${TZ}"
log_info "=============================================="

# Set timezone
if [ -n "$TZ" ]; then
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
    echo $TZ > /etc/timezone
    log_info "Timezone set to: $TZ"
fi

# -----------------------------------------------------------------------------
# Check Architecture
# -----------------------------------------------------------------------------
ARCH=$(uname -m)
log_info "System Architecture: $ARCH"

if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ]; then
    log_warning "This image is optimized for ARM64. Running on $ARCH may have issues."
fi

# Check Box64
if command -v box64 &> /dev/null; then
    log_success "Box64 found: $(box64 --version 2>&1 | head -1 || echo 'installed')"
else
    log_error "Box64 not found! Cannot run x86_64 binaries."
    exit 1
fi

# Check Box86
if command -v box86 &> /dev/null; then
    log_success "Box86 found"
else
    log_warning "Box86 not found. SteamCMD may have issues."
fi

# -----------------------------------------------------------------------------
# Initialize Wine Prefix
# -----------------------------------------------------------------------------
log_info "Initializing Wine prefix..."

# Start virtual framebuffer for Wine
Xvfb :99 -screen 0 1024x768x16 &
export DISPLAY=:99

# Initialize Wine if needed
if [ ! -d "$WINEPREFIX" ]; then
    log_info "Creating new Wine prefix..."
    wineboot --init 2>/dev/null || true
    sleep 5
    wineserver -w 2>/dev/null || true
    log_success "Wine prefix created"
else
    log_info "Wine prefix already exists"
fi

# -----------------------------------------------------------------------------
# Update/Install V Rising via SteamCMD
# -----------------------------------------------------------------------------
update_server() {
    log_info "Checking for V Rising server updates..."
    
    cd ${STEAMCMD_PATH}
    
    # Run SteamCMD with Box86 for 32-bit
    export BOX86_NOBANNER=1
    export BOX86_LOG=0
    
    ./steamcmd.sh \
        +@sSteamCmdForcePlatformType windows \
        +force_install_dir "${SERVER_PATH}" \
        +login anonymous \
        +app_update ${STEAM_APP_ID} validate \
        +quit
    
    if [ $? -eq 0 ]; then
        log_success "V Rising server updated successfully"
    else
        log_warning "SteamCMD returned non-zero exit code"
    fi
}

# Check if server needs update
if [ ! -f "${SERVER_PATH}/VRisingServer.exe" ]; then
    log_info "V Rising server not found. Installing..."
    update_server
elif [ "${UPDATE_SERVER:-true}" = "true" ]; then
    update_server
fi

# Verify installation
if [ ! -f "${SERVER_PATH}/VRisingServer.exe" ]; then
    log_error "VRisingServer.exe not found after installation!"
    log_error "Check SteamCMD output above for errors."
    exit 1
fi

log_success "V Rising server files verified"

# -----------------------------------------------------------------------------
# Setup Configuration Files
# -----------------------------------------------------------------------------
log_info "Setting up configuration files..."

# Create Settings directory if needed
mkdir -p "${DATA_PATH}/Settings"

# ServerHostSettings.json
if [ ! -f "${DATA_PATH}/Settings/ServerHostSettings.json" ]; then
    log_info "Creating ServerHostSettings.json..."
    cp /opt/config/ServerHostSettings.json "${DATA_PATH}/Settings/" 2>/dev/null || \
    cat > "${DATA_PATH}/Settings/ServerHostSettings.json" << EOF
{
  "Name": "${SERVERNAME}",
  "Description": "V Rising ARM64 Server",
  "Port": 9876,
  "QueryPort": 9877,
  "MaxConnectedUsers": 10,
  "MaxConnectedAdmins": 2,
  "SaveName": "world1",
  "Password": "",
  "Secure": true,
  "ListOnSteam": false,
  "ListOnEOS": false,
  "AutoSaveCount": 20,
  "AutoSaveInterval": 300,
  "CompressSaveFiles": true,
  "Rcon": {
    "Enabled": false,
    "Port": 25575,
    "Password": ""
  }
}
EOF
fi

# ServerGameSettings.json
if [ ! -f "${DATA_PATH}/Settings/ServerGameSettings.json" ]; then
    log_info "Creating ServerGameSettings.json..."
    if [ -f "/opt/config/ServerGameSettings.json" ]; then
        cp /opt/config/ServerGameSettings.json "${DATA_PATH}/Settings/"
    fi
fi

# Update server name in settings
if [ -f "${DATA_PATH}/Settings/ServerHostSettings.json" ]; then
    # Use sed to update server name if it differs
    sed -i "s/\"Name\": \"[^\"]*\"/\"Name\": \"${SERVERNAME}\"/" "${DATA_PATH}/Settings/ServerHostSettings.json"
fi

log_success "Configuration files ready"

# -----------------------------------------------------------------------------
# Setup BepInEx (if enabled)
# -----------------------------------------------------------------------------
if [ "${ENABLE_PLUGINS}" = "true" ]; then
    log_info "Setting up BepInEx..."
    
    BEPINEX_DIR="${SERVER_PATH}/BepInEx"
    
    # Check if BepInEx core files exist
    if [ ! -f "${BEPINEX_DIR}/core/BepInEx.Core.dll" ]; then
        log_info "Installing BepInEx..."
        
        if [ -d "/opt/bepinex" ] && [ "$(ls -A /opt/bepinex 2>/dev/null)" ]; then
            # Copy pre-packaged BepInEx
            cp -r /opt/bepinex/* "${SERVER_PATH}/"
            log_success "BepInEx installed from pre-packaged files"
        else
            # Download BepInEx
            log_info "Downloading BepInEx..."
            BEPINEX_URL="https://github.com/BepInEx/BepInEx/releases/download/v6.0.0-be.752/BepInEx-Unity.IL2CPP-win-x64-6.0.0-be.752.zip"
            
            cd /tmp
            wget -q "${BEPINEX_URL}" -O bepinex.zip
            unzip -o bepinex.zip -d "${SERVER_PATH}/"
            rm bepinex.zip
            
            log_success "BepInEx downloaded and installed"
        fi
    else
        log_info "BepInEx already installed"
    fi
    
    # Create plugins directory
    mkdir -p "${BEPINEX_DIR}/plugins"
    mkdir -p "${BEPINEX_DIR}/config"
    
    # Setup Wine DLL override for doorstop
    log_info "Configuring Wine for BepInEx doorstop..."
    
    # Set winhttp override for doorstop
    wine reg add "HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides" /v winhttp /t REG_SZ /d native,builtin /f 2>/dev/null || true
    
    # Apply Box64 configuration for BepInEx
    if [ -f "${BEPINEX_DIR}/addition_stuff/box64.rc" ]; then
        log_info "Applying custom Box64 configuration..."
        export BOX64_RCFILE="${BEPINEX_DIR}/addition_stuff/box64.rc"
    fi
    
    log_success "BepInEx configuration complete"
else
    log_info "Plugins disabled (ENABLE_PLUGINS=${ENABLE_PLUGINS})"
fi

# -----------------------------------------------------------------------------
# Start V Rising Server
# -----------------------------------------------------------------------------
log_info "=============================================="
log_info "Starting V Rising Server..."
log_info "=============================================="

cd "${SERVER_PATH}"

# Build command line arguments
SERVER_ARGS="-persistentDataPath ${DATA_PATH}"
SERVER_ARGS="${SERVER_ARGS} -serverName \"${SERVERNAME}\""
SERVER_ARGS="${SERVER_ARGS} -saveName world1"
SERVER_ARGS="${SERVER_ARGS} -logFile ${DATA_PATH}/VRisingServer.log"

log_info "Server arguments: ${SERVER_ARGS}"

# Start the server with Wine via Box64
if [ "${ENABLE_PLUGINS}" = "true" ]; then
    log_info "Starting with BepInEx enabled..."
    
    # Doorstop environment variables
    export DOORSTOP_ENABLED=1
    export DOORSTOP_TARGET_ASSEMBLY="${SERVER_PATH}/BepInEx/core/BepInEx.Unity.IL2CPP.dll"
    export DOORSTOP_MONO_LIB_PATHS="${SERVER_PATH}/BepInEx/core"
fi

# Start server in background and capture PID
wine64 VRisingServer.exe ${SERVER_ARGS} &
VRISING_PID=$!

log_success "V Rising Server started with PID: ${VRISING_PID}"
log_info "Server log: ${DATA_PATH}/VRisingServer.log"
log_info "=============================================="

# Wait for server process
wait $VRISING_PID
EXIT_CODE=$?

log_warning "V Rising Server exited with code: ${EXIT_CODE}"

# Cleanup
wineserver -k 2>/dev/null || true

exit $EXIT_CODE

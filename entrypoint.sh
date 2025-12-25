#!/bin/bash
# =============================================================================
# V Rising ARM64 Server - Production Entrypoint
# =============================================================================
# Based on tsx-cloud/vrising-ntsync start.sh with improvements
# This script handles:
# - Graceful shutdown with autosave
# - SteamCMD updates
# - Wine initialization
# - BepInEx configuration
# - Server startup and monitoring
# =============================================================================

set -e

# Paths
s=/mnt/vrising/server
p=/mnt/vrising/persistentdata
l="${p}/logs"
SETTINGS="${p}/Settings"

# Default values
LOGDAYS="${LOGDAYS:-30}"
SERVERNAME="${SERVERNAME:-VRising-ARM64}"
ENABLE_PLUGINS="${ENABLE_PLUGINS:-false}"
UPDATE_SERVER="${UPDATE_SERVER:-true}"

# =============================================================================
# Signal Handler - Graceful Shutdown
# =============================================================================
term_handler() {
    echo ""
    echo "=============================================="
    echo "[SHUTDOWN] Signal received. Saving game..."
    echo "=============================================="
    
    PID=$(pgrep -f "VRisingServer.exe" | sort -nr | head -n 1)
    
    if [[ -z $PID ]]; then
        echo "[SHUTDOWN] Could not find VRisingServer.exe PID. Server may already be stopped."
    else
        echo "[SHUTDOWN] Sending SIGINT to PID $PID for graceful shutdown..."
        kill -n SIGINT "$PID" 2>/dev/null || true
        
        # Wait for server to finish (max 60 seconds)
        local count=0
        while kill -0 "$PID" 2>/dev/null && [ $count -lt 60 ]; do
            echo "[SHUTDOWN] Waiting for save to complete... ($count/60s)"
            sleep 1
            ((count++)) || true
        done
        
        if kill -0 "$PID" 2>/dev/null; then
            echo "[SHUTDOWN] Server didn't stop gracefully, forcing termination..."
            kill -9 "$PID" 2>/dev/null || true
        fi
    fi
    
    # Stop wineserver
    wineserver -k 2>/dev/null || true
    
    echo "[SHUTDOWN] Server stopped successfully."
    exit 0
}

trap 'term_handler' SIGTERM SIGINT SIGQUIT

# =============================================================================
# Logging Functions
# =============================================================================
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo "[OK] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# =============================================================================
# Cleanup old logs
# =============================================================================
cleanup_logs() {
    if [ -d "${l}" ]; then
        log_info "Cleaning up logs older than $LOGDAYS days..."
        find "${l}" -name "*.log" -type f -mtime +$LOGDAYS -exec rm {} \; 2>/dev/null || true
    fi
}

# =============================================================================
# Print Version Information
# =============================================================================
print_versions() {
    echo ""
    echo "=============================================="
    echo "V Rising ARM64 Server - Version Info"
    echo "=============================================="
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    
    if command -v box64 &> /dev/null; then
        # Ensure banner is suppressed for this check
        export BOX64_NOBANNER=1
        BOX64_VER=$(box64 --version 2>&1 | head -1 || echo "installed")
        echo "Box64: $BOX64_VER"
    fi
    
    if command -v box86 &> /dev/null; then
        # Ensure banner is suppressed for this check
        export BOX86_NOBANNER=1
        BOX86_VER=$(box86 --version 2>&1 | head -1 || echo "installed")
        echo "Box86: $BOX86_VER"
    fi
    
    if command -v wine &> /dev/null; then
        WINE_VERSION_OUTPUT=$(wine --version 2>&1)
        WINE_EXIT_CODE=$?
        if [ $WINE_EXIT_CODE -eq 0 ]; then
            echo "Wine: $WINE_VERSION_OUTPUT"
        else
            echo "Wine: ERROR - Failed to execute Wine"
            echo "Wine error output: $WINE_VERSION_OUTPUT"
            if echo "$WINE_VERSION_OUTPUT" | grep -q "could not load ntdll.so"; then
                log_error "Wine ntdll.so loading failure detected!"
                log_error "This indicates BOX64_LD_LIBRARY_PATH misconfiguration in Wine wrappers."
                log_error "Please rebuild the Docker image to fix Wine library paths."
                exit 1
            fi
        fi
    fi
    
    echo "Server Name: $SERVERNAME"
    echo "Plugins: $ENABLE_PLUGINS"
    echo "=============================================="
    echo ""
}

# =============================================================================
# Load Emulator Configuration
# =============================================================================
load_emulator_config() {
    if [ -f "/emulators.rc" ]; then
        log_info "Loading Box64/Box86 configuration..."
        source /emulators.rc
    fi
    
    # Also load from BepInEx if exists
    if [ -f "$s/BepInEx/addition_stuff/box64.rc" ]; then
        log_info "Loading BepInEx Box64 configuration..."
        # Parse the rc file and export variables
        while IFS= read -r line; do
            if [[ $line =~ ^BOX64_ ]] || [[ $line =~ ^export\ BOX64_ ]]; then
                eval "export $line" 2>/dev/null || true
            fi
        done < "$s/BepInEx/addition_stuff/box64.rc"
    fi
    
    # Register binfmt_misc for automatic x86/x86_64 emulation
    # This allows steamcmd.sh and other scripts to work transparently
    setup_binfmt_misc
}

# =============================================================================
# Setup binfmt_misc for Box64/Box86
# =============================================================================
setup_binfmt_misc() {
    # Check if binfmt_misc is mounted
    if [ ! -d "/proc/sys/fs/binfmt_misc" ]; then
        log_warning "binfmt_misc not available - mounting..."
        mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc 2>/dev/null || true
    fi
    
    if [ -d "/proc/sys/fs/binfmt_misc" ] && [ -f "/proc/sys/fs/binfmt_misc/register" ]; then
        log_info "Registering Box64/Box86 with binfmt_misc..."
        
        # Unregister existing entries if present
        echo -1 > /proc/sys/fs/binfmt_misc/box64 2>/dev/null || true
        echo -1 > /proc/sys/fs/binfmt_misc/box86 2>/dev/null || true
        
        # Register Box64 for x86_64 binaries
        echo ':box64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00:\xff\xff\xff\xff\xff\xfe\xfe\x00\x00\x00\x00\x00\x00\x00\x00\x00\xfe\xff\xff\xff:/usr/local/bin/box64:OCF' > /proc/sys/fs/binfmt_misc/register 2>/dev/null || log_warning "Could not register Box64 with binfmt_misc"
        
        # Register Box86 for x86 (32-bit) binaries
        echo ':box86:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x03\x00:\xff\xff\xff\xff\xff\xfe\xfe\x00\x00\x00\x00\x00\x00\x00\x00\x00\xfe\xff\xff\xff:/usr/local/bin/box86:OCF' > /proc/sys/fs/binfmt_misc/register 2>/dev/null || log_warning "Could not register Box86 with binfmt_misc"
        
        if [ -f "/proc/sys/fs/binfmt_misc/box64" ]; then
            log_success "Box64 registered with binfmt_misc"
        fi
        if [ -f "/proc/sys/fs/binfmt_misc/box86" ]; then
            log_success "Box86 registered with binfmt_misc"
        fi
    else
        log_warning "binfmt_misc not available - x86 binaries will need explicit Box64/Box86 invocation"
    fi
}

# =============================================================================
# Check NTSync Support
# =============================================================================
check_ntsync() {
    echo ""
    log_info "Checking NTSync support..."
    echo "Note: NTSync is available in Linux kernel 6.14+ (expected March 2025)"
    echo "Kernel version: $(uname -r)"
    
    if [ -e "/dev/ntsync" ]; then
        if lsof /dev/ntsync > /dev/null 2>&1; then
            log_success "NTSync is available and running!"
        else
            log_info "NTSync device exists but not in use. Wine will use it when needed."
        fi
    else
        log_info "NTSync not available. Server will work fine without it."
    fi
    echo ""
}

# =============================================================================
# Setup BepInEx
# =============================================================================
setup_bepinex() {
    log_info "Checking BepInEx installation..."
    
    mkdir -p "$s"
    
    if [ ! -d "$s/BepInEx" ]; then
        log_info "Installing BepInEx from defaults..."
        if [ -d "/opt/defaults/server" ] && [ "$(ls -A /opt/defaults/server 2>/dev/null)" ]; then
            cp -r /opt/defaults/server/. "$s/"
            log_success "BepInEx installed successfully"
        else
            log_warning "No default BepInEx files found. Plugins may not work."
        fi
    else
        log_info "BepInEx already installed"
    fi
    
    # Create required directories
    mkdir -p "$s/BepInEx/plugins"
    mkdir -p "$s/BepInEx/config"
    mkdir -p "$s/BepInEx/patchers"
}

# =============================================================================
# Update Server via SteamCMD
# =============================================================================
update_server() {
    log_info "Updating V Rising Dedicated Server via SteamCMD..."
    echo ""
    
    steamcmd.sh \
        +@sSteamCmdForcePlatformType windows \
        +force_install_dir "$s" \
        +login anonymous \
        +app_update 1829350 validate \
        +quit
    
    if [ $? -eq 0 ]; then
        log_success "Server updated successfully"
        if [ -f "$s/steam_appid.txt" ]; then
            echo "Steam App ID: $(cat "$s/steam_appid.txt")"
        fi
    else
        log_warning "SteamCMD returned non-zero exit code. Server may still work."
    fi
    echo ""
}

# =============================================================================
# Setup Configuration Files
# =============================================================================
setup_config() {
    log_info "Setting up configuration files..."
    
    mkdir -p "$SETTINGS"
    
    # Copy ServerGameSettings if not exists
    if [ ! -f "$SETTINGS/ServerGameSettings.json" ]; then
        if [ -f "/opt/defaults/config/ServerGameSettings.json" ]; then
            cp "/opt/defaults/config/ServerGameSettings.json" "$SETTINGS/"
            log_info "Created ServerGameSettings.json from template"
        elif [ -f "$s/VRisingServer_Data/StreamingAssets/Settings/ServerGameSettings.json" ]; then
            cp "$s/VRisingServer_Data/StreamingAssets/Settings/ServerGameSettings.json" "$SETTINGS/"
            log_info "Created ServerGameSettings.json from game defaults"
        fi
    fi
    
    # Copy ServerHostSettings if not exists
    if [ ! -f "$SETTINGS/ServerHostSettings.json" ]; then
        if [ -f "/opt/defaults/config/ServerHostSettings.json" ]; then
            cp "/opt/defaults/config/ServerHostSettings.json" "$SETTINGS/"
            log_info "Created ServerHostSettings.json from template"
        elif [ -f "$s/VRisingServer_Data/StreamingAssets/Settings/ServerHostSettings.json" ]; then
            cp "$s/VRisingServer_Data/StreamingAssets/Settings/ServerHostSettings.json" "$SETTINGS/"
            log_info "Created ServerHostSettings.json from game defaults"
        fi
    fi
    
    log_success "Configuration files ready"
}

# =============================================================================
# Setup Logs
# =============================================================================
setup_logs() {
    mkdir -p "$l"
    cleanup_logs
    
    current_date=$(date +"%Y%m%d-%H%M")
    LOGFILE="${current_date}-VRisingServer.log"
    
    if [ ! -f "${l}/${LOGFILE}" ]; then
        touch "${l}/${LOGFILE}"
    fi
    
    log_info "Log file: ${l}/${LOGFILE}"
    
    # Export for use in server start
    export CURRENT_LOGFILE="${l}/${LOGFILE}"
}

# =============================================================================
# Initialize Wine
# =============================================================================
init_wine() {
    log_info "Initializing Wine..."
    
    # Remove stale X lock
    rm -f /tmp/.X0-lock /tmp/.X99-lock 2>/dev/null || true
    
    # Start Xvfb
    log_info "Starting Xvfb virtual display..."
    Xvfb :0 -screen 0 1024x768x16 &
    sleep 3
    
    export DISPLAY=:0
    
    # Disable sound in Wine (not needed for server)
    winetricks sound=disabled 2>/dev/null || true
    
    # Initialize Wine prefix
    log_info "Initializing Wine prefix..."
    wineboot --init 2>/dev/null || true
    sleep 2
    
    log_success "Wine initialized"
}

# =============================================================================
# Configure Plugins (BepInEx)
# =============================================================================
configure_plugins() {
    echo ""
    
    if [ "$ENABLE_PLUGINS" = "true" ]; then
        log_info "Plugins support is ENABLED"
        
        # Configure doorstop
        if [ -f "$s/doorstop_config.ini" ]; then
            sed -i "s/^enabled *=.*/enabled = true/" "$s/doorstop_config.ini"
        fi
        
        # Set Wine DLL override for BepInEx
        export WINEDLLOVERRIDES="winhttp=n,b"
        
        log_info "Wine DLL overrides: $WINEDLLOVERRIDES"
    else
        log_info "Plugins support is DISABLED"
        
        # Disable doorstop
        if [ -f "$s/doorstop_config.ini" ]; then
            sed -i "s/^enabled *=.*/enabled = false/" "$s/doorstop_config.ini"
        fi
    fi
    echo ""
}

# =============================================================================
# Start V Rising Server
# =============================================================================
start_server() {
    cd "$s" || {
        log_error "Failed to change to server directory: $s"
        exit 1
    }
    
    echo ""
    echo "=============================================="
    echo "Starting V Rising Dedicated Server"
    echo "=============================================="
    echo "Server Name: $SERVERNAME"
    echo "Data Path: $p"
    echo "Log File: $CURRENT_LOGFILE"
    echo "Plugins: $ENABLE_PLUGINS"
    echo "=============================================="
    echo ""
    
    # Start the server
    wine "$s/VRisingServer.exe" \
        -serverName "$SERVERNAME" \
        -persistentDataPath "$p" \
        -logFile "$CURRENT_LOGFILE" \
        -nographics \
        -batchmode 2>&1 &
    
    ServerPID=$!
    
    log_success "Server started with PID: $ServerPID"
    
    # Tail log file and wait for server
    sleep 5
    if [ -f "$CURRENT_LOGFILE" ]; then
        tail -n 0 -f "$CURRENT_LOGFILE" &
    fi
    
    wait $ServerPID
    EXIT_CODE=$?
    
    log_warning "Server exited with code: $EXIT_CODE"
    return $EXIT_CODE
}

# =============================================================================
# Main Execution
# =============================================================================
main() {
    echo ""
    echo "=============================================="
    echo "V Rising ARM64 Server - Starting"
    echo "=============================================="
    echo ""
    
    # Print version info
    print_versions
    
    # Load emulator settings
    load_emulator_config
    
    # Check NTSync
    check_ntsync
    
    # Setup BepInEx
    setup_bepinex
    
    # Update server (if enabled)
    if [ "$UPDATE_SERVER" = "true" ]; then
        update_server
    else
        log_info "Server update skipped (UPDATE_SERVER=false)"
    fi
    
    # Verify server executable exists
    if [ ! -f "$s/VRisingServer.exe" ]; then
        log_error "VRisingServer.exe not found!"
        log_error "Run with UPDATE_SERVER=true to download the server."
        exit 1
    fi
    
    # Setup configuration
    setup_config
    
    # Setup logs
    setup_logs
    
    # Initialize Wine
    init_wine
    
    # Configure plugins
    configure_plugins
    
    # Start server
    start_server
}

# Run main function
main

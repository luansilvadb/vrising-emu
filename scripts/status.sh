#!/bin/bash
# =============================================================================
# Server Status Check
# =============================================================================
# Quick status check for V Rising server
# =============================================================================

echo "=============================================="
echo "V Rising ARM64 Server Status"
echo "=============================================="
echo ""

# Check if server process is running
if pgrep -f "VRisingServer.exe" > /dev/null 2>&1; then
    PID=$(pgrep -f "VRisingServer.exe" | head -1)
    echo "Server: RUNNING (PID: $PID)"
    
    # Get memory usage
    if [ -f "/proc/$PID/status" ]; then
        MEM=$(grep VmRSS /proc/$PID/status | awk '{print $2}')
        MEM_MB=$((MEM / 1024))
        echo "Memory: ${MEM_MB} MB"
    fi
else
    echo "Server: STOPPED"
fi

echo ""

# Check Wine
if pgrep -f "wineserver" > /dev/null 2>&1; then
    echo "Wine: RUNNING"
else
    echo "Wine: STOPPED"
fi

# Check Xvfb
if pgrep -f "Xvfb" > /dev/null 2>&1; then
    echo "Xvfb: RUNNING"
else
    echo "Xvfb: STOPPED"
fi

echo ""

# Check NTSync
if [ -e "/dev/ntsync" ]; then
    echo "NTSync: AVAILABLE"
else
    echo "NTSync: NOT AVAILABLE"
fi

echo ""

# Disk usage
if [ -d "/mnt/vrising" ]; then
    echo "Disk Usage:"
    du -sh /mnt/vrising/server 2>/dev/null | awk '{print "  Server: " $1}'
    du -sh /mnt/vrising/persistentdata 2>/dev/null | awk '{print "  Data: " $1}'
fi

echo ""

# Latest log
LOG_DIR="/mnt/vrising/persistentdata/logs"
if [ -d "$LOG_DIR" ]; then
    LATEST_LOG=$(ls -t "$LOG_DIR"/*.log 2>/dev/null | head -1)
    if [ -n "$LATEST_LOG" ]; then
        echo "Latest log: $(basename $LATEST_LOG)"
        echo "Last 5 lines:"
        tail -5 "$LATEST_LOG" | sed 's/^/  /'
    fi
fi

echo ""
echo "=============================================="

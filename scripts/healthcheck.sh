#!/bin/bash
# =============================================================================
# Health Check Script
# =============================================================================
# Used for Docker HEALTHCHECK
# Returns 0 if server is running, 1 otherwise

# Check if VRisingServer process is running
if pgrep -f "VRisingServer" > /dev/null 2>&1; then
    exit 0
else
    exit 1
fi

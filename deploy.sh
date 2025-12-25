#!/bin/bash
# =============================================================================
# Quick Deploy Script - V Rising ARM64 with Wine Fix
# =============================================================================
# Run this on your Oracle Cloud ARM64 server after pulling the updated code
#
# Usage: ./deploy.sh

set -e

echo "=========================================="
echo "V Rising ARM64 - Emergency Wine Fix Deploy"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Stop existing container
step "Stopping existing container..."
docker-compose down 2>/dev/null || warn "No container was running"
echo ""

# Step 2: Clean old images (optional)
read -p "Clean old Docker images? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    step "Cleaning old images..."
    docker image prune -f
fi
echo ""

# Step 3: Rebuild
step "Rebuilding Docker image (this will take 20-40 minutes)..."
echo "Watch for 'Wine lib directories' output to confirm fix..."
echo ""

docker-compose build --no-cache runtime

if [ $? -ne 0 ]; then
    error "Build failed! Check output above."
    exit 1
fi

echo ""
step "Build completed successfully!"
echo ""

# Step 4: Start server
step "Starting server..."
docker-compose up -d

if [ $? -ne 0 ]; then
    error "Failed to start server!"
    exit 1
fi

echo ""
step "Server started! Waiting 10 seconds for initialization..."
sleep 10
echo ""

# Step 5: Verify
step "Verifying Wine installation..."
docker exec vrising-arm64 wine --version

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Wine is working!${NC}"
else
    error "Wine verification failed!"
    echo "Check logs with: docker-compose logs -f"
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Deployment Complete!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Monitor logs: docker-compose logs -f"
echo "2. Wait for server download (~10 minutes first time)"
echo "3. Check process: docker exec vrising-arm64 pgrep -a VRisingServer"
echo ""
echo "Server ports:"
echo "  - Game: 9876/udp"
echo "  - Query: 9877/udp"
echo ""

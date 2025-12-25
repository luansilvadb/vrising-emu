#!/bin/bash
# =============================================================================
# Backup V Rising Server Data
# =============================================================================
# Creates a backup of persistent data (saves, configs)
# Run inside container: docker exec vrising /opt/scripts/backup.sh
# =============================================================================

set -e

DATA_PATH="${DATA_PATH:-/mnt/vrising/persistentdata}"
BACKUP_DIR="${BACKUP_DIR:-/mnt/vrising/backups}"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
BACKUP_NAME="vrising-backup-${TIMESTAMP}.tar.gz"

echo "=============================================="
echo "V Rising Server Backup"
echo "=============================================="
echo "Data path: ${DATA_PATH}"
echo "Backup dir: ${BACKUP_DIR}"
echo "Backup name: ${BACKUP_NAME}"
echo ""

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Check if data exists
if [ ! -d "${DATA_PATH}" ]; then
    echo "[ERROR] Data path not found: ${DATA_PATH}"
    exit 1
fi

# Create backup
echo "Creating backup..."
cd "${DATA_PATH}"
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}" \
    --exclude='logs' \
    --exclude='*.log' \
    .

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}" | cut -f1)
    echo ""
    echo "[OK] Backup created successfully!"
    echo "File: ${BACKUP_DIR}/${BACKUP_NAME}"
    echo "Size: ${BACKUP_SIZE}"
    
    # Cleanup old backups (keep last 7)
    echo ""
    echo "Cleaning up old backups (keeping last 7)..."
    ls -t "${BACKUP_DIR}"/vrising-backup-*.tar.gz 2>/dev/null | tail -n +8 | xargs -r rm -f
    
    # List remaining backups
    echo "Current backups:"
    ls -lh "${BACKUP_DIR}"/vrising-backup-*.tar.gz 2>/dev/null || echo "  (none)"
else
    echo "[ERROR] Backup failed!"
    exit 1
fi

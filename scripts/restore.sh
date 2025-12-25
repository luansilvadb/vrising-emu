#!/bin/bash
# =============================================================================
# Restore V Rising Server Data from Backup
# =============================================================================
# Usage: docker exec vrising /opt/scripts/restore.sh <backup-file>
# =============================================================================

set -e

DATA_PATH="${DATA_PATH:-/mnt/vrising/persistentdata}"
BACKUP_DIR="${BACKUP_DIR:-/mnt/vrising/backups}"

if [ -z "$1" ]; then
    echo "=============================================="
    echo "V Rising Server Restore"
    echo "=============================================="
    echo ""
    echo "Usage: restore.sh <backup-file>"
    echo ""
    echo "Available backups:"
    ls -lh "${BACKUP_DIR}"/vrising-backup-*.tar.gz 2>/dev/null || echo "  (none found)"
    exit 1
fi

BACKUP_FILE="$1"

# Check if it's a full path or just filename
if [[ ! "$BACKUP_FILE" == /* ]]; then
    BACKUP_FILE="${BACKUP_DIR}/${BACKUP_FILE}"
fi

echo "=============================================="
echo "V Rising Server Restore"
echo "=============================================="
echo "Backup file: ${BACKUP_FILE}"
echo "Target: ${DATA_PATH}"
echo ""

# Check if backup exists
if [ ! -f "${BACKUP_FILE}" ]; then
    echo "[ERROR] Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

# Confirm restoration
echo "[WARN] This will overwrite current data!"
echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
sleep 5

# Create target directory if needed
mkdir -p "${DATA_PATH}"

# Restore backup
echo "Restoring backup..."
cd "${DATA_PATH}"
tar -xzf "${BACKUP_FILE}"

if [ $? -eq 0 ]; then
    echo ""
    echo "[OK] Restore completed successfully!"
    echo "Restart the server to apply changes."
else
    echo "[ERROR] Restore failed!"
    exit 1
fi

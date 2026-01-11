#!/bin/bash
set -e

LOG_FILE="/var/log/db-backup.log"
SOURCE_DIR="/opt/db-backups/postgres/"
DEST_USER="azureuser2"
DEST_IP="20.205.9.238"
DEST_DIR="/data/db-backups"
KEY_PATH="/home/azureuser1/db_bkp_key"

echo "📤 Copying backups to Backup VM..." | tee -a "$LOG_FILE"

scp -i $KEY_PATH -r "$SOURCE_DIR" "${DEST_USER}@${DEST_IP}:${DEST_DIR}"

echo "✅ Backup copied successfully to Backup VM" | tee -a "$LOG_FILE"

# Retention on BACKUP VM (7 days)
ssh -i $KEY_PATH ${DEST_USER}@${DEST_IP} \
"find $DEST_DIR -type f -mtime +7 -delete"

echo "🧹 Old backups cleaned from BACKUP VM" | tee -a "$LOG_FILE"
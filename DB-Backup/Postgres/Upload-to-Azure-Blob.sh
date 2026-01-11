#!/bin/bash
set -e

LOG_FILE="/var/log/db-backup.log"

# Azure details
STORAGE_ACCOUNT="postgresdbbkp"
CONTAINER_NAME="db-backup"

# Backup source
SOURCE_DIR="/opt/db-backups/postgres"

echo "☁️ Starting upload to Azure Blob Storage..." | tee -a "$LOG_FILE"

# Upload backups (cost-effective tier)
az storage blob upload-batch \
  --account-name "$STORAGE_ACCOUNT" \
  --destination "$CONTAINER_NAME" \
  --source "$SOURCE_DIR" \
  --tier Cool \
  --overwrite

echo "✅ Upload completed to Azure Blob Storage" | tee -a "$LOG_FILE"

# Azure retention: delete blobs older than 7 days
echo "🧹 Cleaning Azure blobs older than 7 days..." | tee -a "$LOG_FILE"

az storage blob list \
  --account-name "$STORAGE_ACCOUNT" \
  --container-name "$CONTAINER_NAME" \
  --query "[?properties.lastModified < '$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)'].name" \
  -o tsv | while read blob; do
    az storage blob delete \
      --account-name "$STORAGE_ACCOUNT" \
      --container-name "$CONTAINER_NAME" \
      --name "$blob"
  done

echo "🧹 Azure Blob retention cleanup completed" | tee -a "$LOG_FILE"
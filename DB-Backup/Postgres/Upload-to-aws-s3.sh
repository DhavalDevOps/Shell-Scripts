#!/bin/bash
set -e

LOG_FILE="/var/log/db-backup.log"

# AWS S3 details
S3_BUCKET="s3://my-db-backups-<unique>/db-backups"

# Backup source
SOURCE_DIR="/opt/db-backups/postgres"

echo "☁️ Starting upload to AWS S3..." | tee -a "$LOG_FILE"

# Sync backups to S3 (cost-effective storage)
aws s3 sync "$SOURCE_DIR" "$S3_BUCKET" \
  --storage-class STANDARD_IA

echo "✅ Upload completed to AWS S3" | tee -a "$LOG_FILE"

# Retention: delete objects older than 7 days
echo "🧹 Cleaning S3 backups older than 7 days..." | tee -a "$LOG_FILE"

aws s3 ls "$S3_BUCKET/" --recursive | while read -r line; do
  file_date=$(echo "$line" | awk '{print $1" "$2}')
  file_name=$(echo "$line" | awk '{print $4}')

  if [[ ! -z "$file_name" ]]; then
    file_epoch=$(date -d "$file_date" +%s)
    limit_epoch=$(date -d "7 days ago" +%s)

    if (( file_epoch < limit_epoch )); then
      aws s3 rm "$S3_BUCKET/$file_name"
    fi
  fi
done

echo "🧹 S3 retention cleanup completed" | tee -a "$LOG_FILE"

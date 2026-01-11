#!/bin/bash
set -e

LOG_FILE="/var/log/db-backup.log"
DATE=$(date +%F_%H-%M-%S)
DB_NAME="mydb"
BACKUP_DIR="/opt/db-backups/postgres/standalone"
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${DATE}.sql"

mkdir -p "$BACKUP_DIR"

echo "📦 Starting Standalone PostgreSQL Backup..." | tee -a "$LOG_FILE"

pg_dump -h localhost -U postgres "$DB_NAME" > "$BACKUP_FILE"

echo "✅ PostgreSQL Backup Completed: $BACKUP_FILE" | tee -a "$LOG_FILE"

# Retention (7 days)
find "$BACKUP_DIR" -type f -mtime +7 -delete

echo "🧹 Old backups cleaned from SOURCE VM" | tee -a "$LOG_FILE"
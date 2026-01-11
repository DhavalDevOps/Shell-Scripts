#!/bin/bash
set -e

LOG_FILE="/var/log/db-backup.log"
DATE=$(date +%F_%H-%M-%S)

# Docker details
CONTAINER_NAME="pg-container"
DB_NAME="mydb"
DB_USER="postgres"

BACKUP_DIR="/opt/db-backups/postgres/docker"
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_docker_${DATE}.sql"

mkdir -p "$BACKUP_DIR"

echo "🐳 Starting Docker PostgreSQL Backup..." | tee -a "$LOG_FILE"
echo "➡️ Container: $CONTAINER_NAME | DB: $DB_NAME" | tee -a "$LOG_FILE"

docker exec "$CONTAINER_NAME" \
pg_dump -U "$DB_USER" "$DB_NAME" \
> "$BACKUP_FILE"

echo "✅ Docker PostgreSQL Backup Completed: $BACKUP_FILE" | tee -a "$LOG_FILE"

# Retention: delete backups older than 7 days
find "$BACKUP_DIR" -type f -mtime +7 -delete

echo "🧹 Old backups cleaned from SOURCE VM (Docker DB)" | tee -a "$LOG_FILE"

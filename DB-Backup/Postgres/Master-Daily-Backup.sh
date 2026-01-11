#!/bin/bash
set -e

LOG_FILE="/var/log/db-backup.log"
EMAIL="dhaval.chhayla.devops@gmail.com"

# Log to terminal + file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "==================================="
echo "🚀 DB Backup Job Started: $(date)"
echo "==================================="

# Standalone PostgreSQL
/opt/db-backups/postgres-standalone-backup.sh

# Docker PostgreSQL
/opt/db-backups/postgres-docker-backup.sh

# Copy backups to backup VM
/opt/db-backups/copy-to-backup-vm.sh

# Upload to Azure Blob
/opt/db-backups/upload-to-azure.sh  

# Upload to AWS S3
/opt/db-backups/upload-to-s3.sh

echo "🎉 DB Backup Job Finished Successfully: $(date)"

echo "Database Backup Successful on $(hostname)" \
 | mail -s "DB Backup SUCCESS" "$EMAIL"

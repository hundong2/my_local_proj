#!/bin/bash

# Keycloak Database Backup Script

set -e

BACKUP_DIR="./backups/keycloak"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="keycloak_backup_$TIMESTAMP.sql"

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "Creating Keycloak database backup..."

# Check if PostgreSQL container is running
if ! docker-compose ps postgres | grep -q "Up"; then
    echo "PostgreSQL container is not running. Please start the services first."
    exit 1
fi

# Get database credentials from environment
source .env 2>/dev/null || true
POSTGRES_USER=${POSTGRES_USER:-keycloak}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-keycloak123}

# Create database backup
docker-compose exec -T postgres pg_dump -U "$POSTGRES_USER" -d keycloak > "$BACKUP_DIR/$BACKUP_FILE"

# Compress the backup
gzip "$BACKUP_DIR/$BACKUP_FILE"

echo "Backup created: $BACKUP_DIR/$BACKUP_FILE.gz"

# Keep only last 7 backups
find "$BACKUP_DIR" -name "keycloak_backup_*.sql.gz" -mtime +7 -delete

echo "Backup cleanup complete. Keeping last 7 backups."

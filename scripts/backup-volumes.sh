#!/bin/bash

# Docker Volumes Backup Script

set -e

BACKUP_DIR="./backups/volumes"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "Creating Docker volumes backup..."

# List of volumes to backup
VOLUMES=("postgres-data" "keycloak-data" "openwebui-data" "code-server-data")

# Get the project name (used as prefix for volume names)
PROJECT_NAME=$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')

for VOLUME in "${VOLUMES[@]}"; do
    FULL_VOLUME_NAME="${PROJECT_NAME}_${VOLUME}"
    BACKUP_FILE="$BACKUP_DIR/${VOLUME}_$TIMESTAMP.tar.gz"
    
    echo "Backing up volume: $FULL_VOLUME_NAME"
    
    # Create backup using a temporary container
    docker run --rm \
        -v "$FULL_VOLUME_NAME:/data:ro" \
        -v "$PWD/$BACKUP_DIR:/backup" \
        alpine:latest \
        tar czf "/backup/$(basename "$BACKUP_FILE")" -C /data .
    
    echo "Created backup: $BACKUP_FILE"
done

# Keep only last 5 backups for each volume
for VOLUME in "${VOLUMES[@]}"; do
    find "$BACKUP_DIR" -name "${VOLUME}_*.tar.gz" -type f | sort -r | tail -n +6 | xargs -r rm
done

echo "Volume backup complete!"
echo "Backups are stored in: $BACKUP_DIR"

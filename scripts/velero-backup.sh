#!/bin/bash
# velero-backup.sh — Trigger a Velero backup to MinIO

set -euo pipefail

BACKUP_NAME="manual-$(date +%Y%m%d-%H%M%S)"

velero backup create "$BACKUP_NAME" \
  --include-namespaces data,flink,collectors,observability,gitops \
  --storage-location minio \
  --ttl 720h

echo "Backup created: $BACKUP_NAME"

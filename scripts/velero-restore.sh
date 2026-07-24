#!/bin/bash
# velero-restore.sh — Restore cluster from Velero backup

set -euo pipefail

BACKUP_NAME="${1:?Usage: velero-restore.sh <backup-name>}"

# Restore from backup
velero restore create "$BACKUP_NAME" \
  --from-backup "$BACKUP_NAME" \
  --include-namespaces data,flink,collectors,observability,gitops

echo "Restore initiated for backup: $BACKUP_NAME"

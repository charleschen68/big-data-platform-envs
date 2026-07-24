#!/bin/bash
# velero-disaster-recovery.sh — Disaster recovery from Velero backup

set -euo pipefail

BACKUP_NAME="${1:?Usage: velero-disaster-recovery.sh <backup-name>}"

echo "=== Disaster Recovery from Velero Backup ==="

# Delete all namespaces (simulating cluster loss)
echo "Deleting all namespaces..."
kubectl delete namespaces data flink collectors observability gitops --ignore-not-found

# Recreate namespaces
kubectl apply -f environments/current/kustomization.yaml

# Restore from Velero backup
velero restore create disaster-recovery --from-backup "$BACKUP_NAME"

# Wait for restoration
echo "Waiting for restoration..."
kubectl wait --for=condition=ready pod --all -n data --timeout=300s
kubectl wait --for=condition=ready pod --all -n flink --timeout=300s
kubectl wait --for=condition=ready pod --all -n collectors --timeout=300s
kubectl wait --for=condition=ready pod --all -n observability --timeout=300s

echo "=== Disaster recovery complete ==="

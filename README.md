# big-data-platform-envs

GitOps environment repository for big-data-platform.

## Structure

- `environments/current/` — Current environment declarations
  - `applications/` — ArgoCD Application CRs for each namespace
  - `secrets/` — SOPS-encrypted secrets (age)
  - `values/` — Helm values files
  - `overlays/` — Kustomize overlays
  - `kustomization.yaml` — Root kustomization

- `scripts/` — Utility scripts
  - `sops-encrypt.sh` — Encrypt secrets with SOPS
  - `sops-decrypt.sh` — Decrypt secrets with SOPS
  - `velero-backup.sh` — Trigger Velero backup
  - `velero-restore.sh` — Restore from Velero backup
  - `verify-recovery.sh` — Verify VM restart recovery
  - `verify-ollama-fault.sh` — Verify Ollama fault tolerance
  - `velero-disaster-recovery.sh` — Disaster recovery from Velero backup

## Graduation Drills

### 1. VM Restart Recovery
- Restart entire VM
- Verify k3s auto-starts → ArgoCD syncs → all pods start → collectors connect to Kafka → Flink recovers from savepoint → trading signals are not duplicated

### 2. Ollama Fault Tolerance
- Stop Ollama for 10 minutes
- Verify Flink async functions handle timeout/backpressure correctly
- Verify Prometheus alerts trigger and Telegram notifications sent

### 3. Disaster Recovery
- Restore entire cluster from Velero backup
- Verify PVC recovery, etcd recovery, ArgoCD sync, full system availability

## Usage

```bash
# Encrypt a secret
./scripts/sops-encrypt.sh secrets/my-secret.yaml

# Decrypt a secret
./scripts/sops-decrypt.sh secrets/my-secret.sops.yaml

# Trigger backup
./scripts/velero-backup.sh

# Restore from backup
./scripts/velero-restore.sh <backup-name>

# Verify recovery
./scripts/verify-recovery.sh

# Verify Ollama fault tolerance
./scripts/verify-ollama-fault.sh

# Disaster recovery
./scripts/velero-disaster-recovery.sh <backup-name>
```

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

## Quick Start — Run the Cluster

### Prerequisites

- k3s (or any Kubernetes 1.28+)
- kubectl
- sops + age (for encrypted secrets)
- Git

### One-command setup

```bash
# 1. Install k3s (if not already running)
curl -sfL https://get.k3s.io | sh

# 2. Clone this repo
git clone https://github.com/ad/big-data-platform-envs.git
cd big-data-platform-envs

# 3. Apply all configurations
kubectl apply -f environments/current/

# 4. Verify
kubectl get pods -A
kubectl get applications -n gitops
```

### What gets deployed

| Namespace | Components |
|-----------|-----------|
| `gitops` | ArgoCD (server, controller, repo-server, applicationset, dex, redis) |
| `data` | Kafka, MySQL, MinIO, ClickHouse, Milvus, Velero |
| `flink` | Flink Operator |
| `collectors` | RSS Collector, Settlement Worker, Market Collector |
| `observability` | Prometheus, Grafana, Alertmanager |

### Check it's running

```bash
# All pods should be Running (or Completed)
kubectl get pods -A

# ArgoCD Applications should be Synced
kubectl get applications -n gitops

# All namespaces should exist
kubectl get namespaces | grep -E 'gitops|data|flink|collectors|observability'
```

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

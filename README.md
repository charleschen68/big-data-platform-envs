# big-data-platform-envs

The authoritative GitOps environment repository for `big-data-platform`.
It declares the local OrbStack environment; the sibling application repository
owns collector source code, Dockerfiles, and image builds. Do not apply its
legacy `infra/k8s/{data,collectors}` manifests directly.

## Current environment

| Namespace | Declared components |
| --- | --- |
| `gitops` | Argo CD, KSOPS/SOPS plugin, root Application |
| `ingress` | Traefik |
| `data` | Kafka (Strimzi/KRaft), MySQL, ClickHouse, MinIO, Milvus |
| `collectors` | RSS, market, settlement, safe Milvus schema-init, retraining CronJob |
| `observability` | Prometheus, Grafana, collector ServiceMonitors and dashboard |

Flink and Velero are outside the current migration scope and must not be
assumed deployed.

## Bootstrap and access

Prerequisites: a reachable Kubernetes context (default `orbstack`), `kubectl`,
`helm`, `sops`, `age`, and a local age identity file. Bootstrap creates the
cluster-only age Secret from that identity; the private key is never committed.

```bash
export SOPS_AGE_KEY_FILE=/secure/path/keys.txt
./scripts/bootstrap-gitops.sh
```

The bootstrap script installs pinned Traefik and Argo CD chart versions, applies
the `platform` AppProject, then applies the root Application. Thereafter make
environment changes through Git and Argo CD; do not use `kubectl apply` as an
alternate deployment path.

Local-only pages:

- `http://argocd.localhost` — deployment and synchronization status.
- `http://grafana.localhost/d/collector-runtime` — collector readiness,
  staleness, and heartbeat metrics.

Grafana is anonymous Viewer only for this local host route. Argo CD follows its
own authentication policy; do not record credentials in this repository.

## Validate a change

```bash
kubectl kustomize environments/current/
kubectl kustomize environments/current/ | kubectl apply --dry-run=client -f -
git diff --check
kubectl --context orbstack -n gitops get applications.argoproj.io
kubectl --context orbstack get pods -A | rg 'data|collectors|observability'
```

For a validated operational procedure and the evidence/rollback boundaries, see
[the GitOps migration runbook](wiki/2026-08-05-gitops-data-collectors-runbook.md).
The durable architecture decision is recorded in
[the migration design](design/2026-08-05-gitops-data-collectors-migration.md).

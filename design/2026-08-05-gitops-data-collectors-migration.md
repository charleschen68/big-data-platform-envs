# GitOps migration for data services, collectors, and local observability

**Status:** approved
**Owner:** platform owner
**Decision date:** 2026-08-05

## Context

`big-data-platform-envs` is the authoritative environment repository. The
application repository, `big-data-platform`, owns Java and Python source code,
Dockerfiles, and the collector image build/import script. Its existing
`infra/k8s/data` and `infra/k8s/collectors` manifests are migration inputs, not
an ongoing deployment source.

The target OrbStack Kubernetes cluster is a single node with approximately
15.7 GiB allocatable memory. It currently has no Ingress controller, Argo CD,
Strimzi CRDs, or platform namespaces. Existing environment Application CRs
refer to overlays that do not yet exist. The source manifests also contain
plaintext credentials, assume locally imported collector images, and require
the Strimzi operator before Kafka resources can be reconciled.

## Goals and non-goals

### Goals

- Make this repository the only declarative deployment source for data
  services, collectors, Ingress, and observability.
- Bootstrap Argo CD, Traefik, and SOPS/age rendering without storing a private
  key or plaintext credential in Git.
- Reconcile dependencies in a safe order: platform controllers, data services,
  collectors, then dashboards and alerts.
- Expose local-only Argo CD and Grafana pages through Ingress.
- Preserve collector image ownership in `big-data-platform`; GitOps references
  immutable image versions and never builds application images.

### Non-goals

- High availability, multi-node failover, public DNS, public Internet
  exposure, or production TLS in this single-node learning environment.
- A migration of Flink workloads or Velero recovery procedures.
- Importing, recreating, or deleting existing Kafka data, PVCs, or other
  stateful workload data without a separate approved cutover plan.

## Options considered

### Directly apply the application repository manifests

Rejected. This creates two deployment sources and bypasses Argo CD review,
drift detection, and rollback history.

### Commit fully rendered third-party charts

Rejected. It removes Helm rendering at reconciliation time but creates a large,
hard-to-update vendor surface and obscures the ownership boundary.

### Bootstrap controllers once, then use Argo CD Applications from this repository

Selected. Bootstrap is limited to the controllers required to make GitOps work.
All durable workload declarations remain versioned in this repository and are
subsequently reconciled by Argo CD.

## Decision

### Bootstrap boundary

A documented, idempotent bootstrap procedure installs pinned versions of:

1. Traefik in the `ingress` namespace.
2. Argo CD in the `gitops` namespace.
3. Argo CD Config Management Plugin support for SOPS with age.
4. An age private-key Kubernetes Secret in `gitops`, created from the local
   identity only at bootstrap time.
5. The root Application that points Argo CD at this repository.

The private key is never rendered, committed, echoed, or retained in command
logs. The bootstrap procedure must fail closed when the age identity is absent.

### Argo CD application topology and ordering

Applications use explicit sync waves and automated sync only after their
rendering and dependency checks pass:

| Wave | Application | Responsibility |
| --- | --- | --- |
| -30 | `ingress` | Traefik controller and local IngressClass |
| -20 | `minio` | MinIO chart and its persistent volume |
| -20 | `strimzi` | Strimzi operator and Kafka CRDs |
| -10 | `data` | Kafka CRs, MySQL, ClickHouse, Milvus, PVCs, and internal services |
| 0 | `collectors` | ConfigMap, SOPS-managed credentials, service aliases, three collector Deployments, and retraining CronJob |
| 10 | `observability` | Prometheus, Grafana, ServiceMonitors, dashboards, and local Ingresses |

If an earlier wave is unhealthy, later waves must not be reported as started.
Kafka resources are not applied until the Strimzi operator is healthy. Collector
Deployments are not considered healthy until their dependent service endpoints
and readiness probes are healthy.

`data` and `collectors` do not use automated sync for their first rollout.
Their initial synchronization is an explicit operator action after the preceding
application is `Synced` and `Healthy`. Automated reconciliation is retained for
the non-stateful controllers and prerequisite applications.

The data Application ignores only Argo CD's own tracking annotation on
StatefulSets. This compensates for an SSA comparison artifact without masking
workload specification, image, resource, or PVC drift.

The existing `flink` Application is excluded from the root composition during
this migration because its overlay does not exist and Flink is outside the
approved scope. The file may remain as a future migration input, but Argo CD
must not reconcile it until a separately approved Flink overlay exists.

### Configuration and secrets

All data-service and collector credentials use SOPS-encrypted Secret manifests.
The existing invalid secret composition is replaced with a KSOPS generator
layout; the generator, rather than ordinary Kustomize `resources`, decrypts
the encrypted Secret manifests inside the Argo CD plugin and then applies them.
Naming is standardized so MySQL and collector workloads reference the same
explicitly documented credential contract. Plaintext source manifests are not
copied.

Milvus 2.4 reads the MinIO identity from `MINIO_ACCESS_KEY_ID` and
`MINIO_SECRET_ACCESS_KEY`. The obsolete `MINIO_ACCESS_KEY` and
`MINIO_SECRET_KEY` names are not used because they silently fall back to the
image defaults. Milvus probes `/healthz` before it is treated as ready.
Because standalone Milvus embeds etcd and mounts RWO claims, its single-replica
Deployment uses the `Recreate` strategy. A rolling surge could mount the same
embedded-etcd data volume into old and new Pods concurrently.

The upstream KSOPS image does not include the `sops` executable. The local
bootstrap builds the pinned ARM64 `big-data-platform/argocd-ksops-sops` CMP
image from the upstream KSOPS image and an SHA-256-verified SOPS release. The
image is a local-cluster bootstrap artifact; no secret is embedded in it.

The root Kustomization does not set a global namespace. Each resource declares
its own namespace (or an individual overlay sets one), preventing a GitOps root
render from rewriting `data` and `collectors` Secrets into `gitops`.

### Image ownership and supply chain

The application repository retains `dataflow/docker/*Dockerfile` and
`infra/scripts/build-and-import-collectors.sh`. Before collectors are synced,
the operator builds and imports the exact ARM64 image tags into the OrbStack
cluster runtime. The environment repository records those tags in a single
image configuration file. `imagePullPolicy: Never` remains intentional for
this local-runtime workflow. A missing image is a rollout failure, not a reason
to switch silently to a floating remote tag.

### Local Ingress access

Traefik exposes only these local HTTP hostnames:

- `argocd.localhost` for Argo CD.
- `grafana.localhost` for Grafana.

No public DNS, port forwarding, or certificate is part of this migration.
Before enabling the routes, the procedure verifies that the controller is
reachable only from the local host path provided by OrbStack. Any wider network
exposure requires a separate security decision, TLS, and authentication review.

### Capacity budget

The source request values cannot be accepted unchanged without a scheduling
check. The target uses one replica per stateful service and conservative,
explicit requests and limits appropriate to the measured 15.7 GiB node. The
rollout verifies scheduled Pod requests before each subsequent wave. This is
not HA: loss of the node interrupts every component.

The initial local profile reserves 512Mi for MinIO, 1Gi for the dual-role
Kafka node, 512Mi for MySQL, 2Gi for ClickHouse, and 2Gi for Milvus. Kafka
uses one KRaft `KafkaNodePool` replica with a 20Gi `local-path` claim and
`deleteClaim: false`. Strimzi owns broker IDs, KRaft roles, listener protocol
mapping, and generated bootstrap Services; hand-written `KAFKA_*` broker
environment/configuration fields and ad-hoc bootstrap Services are excluded.

## Interfaces and data impact

The stable internal DNS interfaces are:

- `kafka-kafka-bootstrap.data.svc.cluster.local:9092`
- `mysql.data.svc.cluster.local:3306`
- `minio.data.svc.cluster.local:9000`
- `milvus.data.svc.cluster.local:19530`
- `clickhouse.data.svc.cluster.local:9000`

Collectors receive these dependencies through namespaced service aliases and
use the existing `rss-collector`, `market-collector`, `settlement-worker`, and
`model-retrain` workload names. Kafka topic, consumer-group, schema, and
idempotency behavior are unchanged by this manifest migration.

## Failure and rollback behavior

- Failed bootstrap: remove only newly created bootstrap resources after
  recording the failure; never remove unrelated workloads or namespaces.
- Failed chart or Application sync: stop at the failing wave, inspect Argo CD
  conditions and Kubernetes events, and revert the environment-repository
  commit. Do not force sync past a failed dependency.
- Failed collector rollout: scale or revert only the failing collector
  Deployment; retain data services and capture logs, readiness output, and
  Kafka consumer-group evidence.
- Stateful data migration is not in scope. Existing state is neither adopted
  nor destroyed without an explicit owner-approved cutover and recovery plan.

## Observability

Argo CD is the deployment-health source. Grafana provides collector availability,
restart count, CPU and memory usage, Kafka broker health, consumer lag, and
collector error-rate views. A ServiceMonitor or equivalent scrape declaration
is required for each collector health/metrics endpoint. Dashboards alone do not
prove end-to-end ingestion: rollout evidence must also check collector logs and
Kafka consumer groups.

## Validation plan

1. Render each changed Kustomize overlay and run `kubectl apply --dry-run=client`.
2. Confirm SOPS rendering succeeds without printing plaintext.
3. Verify controller and CRD readiness before applying dependent Applications.
4. Confirm every declared Pod is scheduled and ready, with requested resources
   within node allocatable capacity.
5. Confirm all Argo CD Applications are `Synced` and `Healthy`.
6. Open `http://argocd.localhost` and `http://grafana.localhost` from the local
   host and verify unauthorised remote reachability is not introduced.
7. Confirm collector readiness, logs, consumer-group positions, and Grafana
   metrics before declaring ingestion started.

## Open decisions

- Pin exact Helm chart versions and image digests after retrieving the current
  compatible chart metadata during implementation.
- Set final data-service resource requests after rendering and evaluating the
  node scheduling budget.
- Determine whether an existing persistent data set requires a separate
  stateful cutover plan before the `data` Application is first synced.

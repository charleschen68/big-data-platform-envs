# GitOps data and collectors operating runbook

**Owner:** platform owner  
**Validation date:** 2026-08-05  
**Scope:** local OrbStack environment only

## Purpose and prerequisites

Use this runbook to inspect the GitOps-managed data services, collectors, and
their observability. It assumes `kubectl` has access to context `orbstack` and
the operator is authorized to inspect the local cluster. Do not expose, print,
or copy SOPS plaintext or Argo CD credentials.

The environment repository is the sole deployment declaration. The application
repository is responsible only for collector source and image builds. Before a
collector image tag is referenced here, build and import that exact tag into
the OrbStack runtime with the application repository's supported build script.

## Normal observation

```bash
kubectl --context orbstack -n gitops get applications.argoproj.io
kubectl --context orbstack get pods -n data
kubectl --context orbstack get pods -n collectors
kubectl --context orbstack get pods -n observability
```

Expected result: every listed Argo CD Application is `Synced` and `Healthy`;
long-running Pods are `Running` and Ready; `milvus-schema-init` and any
one-shot smoke Job are `Completed`.

Open `http://argocd.localhost` for sync history and
`http://grafana.localhost/d/collector-runtime` for the collector dashboard.
Grafana's dashboard must show three `collector_ready` series. The metric names
are `collector_ready`, `collector_stale`, and
`collector_heartbeat_age_seconds`.

## Validate a proposed environment change

Impact: render and client-side checks do not mutate the cluster.

```bash
kubectl kustomize environments/current/
kubectl kustomize environments/current/ | kubectl apply --dry-run=client -f -
git diff --check
rg -n 'TODO|TBD|FIXME' Instructions.md design wiki standards
```

Expected result: rendering and client dry-run succeed, no whitespace errors,
and no unresolved documentation markers. Commit and push only the reviewed
scope. Argo CD handles the ordinary reconciliation; do not force-sync stateful
resources merely to clear a status.

## Failure signals and escalation

| Signal | Immediate action | Do not do |
| --- | --- | --- |
| Application `OutOfSync` or `Degraded` | Inspect its resource tree, conditions, events, and rendered diff in Argo CD. | Force sync, delete StatefulSets, or delete PVCs. |
| Collector not Ready or `collector_ready == 0` | Inspect that Deployment's logs, readiness endpoint, and Kafka consumer-group membership. | Restart all collectors or change Kafka offsets without an incident decision. |
| Schema-init Job fails | Inspect Job logs and Milvus schema. | Delete or replace an existing collection; the Job intentionally refuses it. |
| Missing collector metric target | Check the collector `/metrics` endpoint, matching Service, and ServiceMonitor. | Disable TLS/authentication or broaden Prometheus discovery. |

Record the observed revision, resource name, namespace, logs/events, and
rollback decision before any mutation. For a failed declarative change, revert
the Git commit and let Argo CD reconcile; this is the normal rollback path.

## Destructive-change boundary

Deleting a StatefulSet, PVC, Kafka topic, consumer-group offsets, or Milvus
collection is outside this runbook. It requires owner approval, a verified
backup/recovery path, declared blast radius, and post-change data validation.

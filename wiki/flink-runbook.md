# Flink 1.18.1 local runtime

Owner: repository owner. Target: context `orbstack`, namespace `flink`.
Prerequisites: reachable cluster, GitOps repository access and Application sync
permissions. Scope: Operator and empty session runtime; no business-job cutover.

## Rollout and acceptance

Publish the reviewed change to `feat/gitops-data-collectors`, the current live
source branch. Let gitops-self reconcile project and child Applications.
Sync flink-operator manually, wait for its Deployment and structural CRDs, then
sync flink. Sync waves on child Applications alone are not a readiness gate.

```bash
kubectl --context orbstack -n flink rollout status deployment/flink-kubernetes-operator --timeout=180s
kubectl --context orbstack -n flink get flinkdeployments,pods,svc
kubectl --context orbstack -n flink port-forward svc/flink-session-rest 8081:8081
# In another terminal:
curl --fail http://127.0.0.1:8081/overview
```

Expected: flink-version 1.18.1, one TaskManager, two slots. Port forwarding is
local-only. No ingress or public REST endpoint is declared.

## Failure and recovery

ImagePullBackOff: verify digest and registry connectivity. Reconciliation errors:
inspect Operator logs and FlinkDeployment status. A session runtime is not HA;
node or JobManager loss may lose submitted jobs. Do not submit stateful business
jobs until S3 credentials are SOPS-encrypted in namespace flink, buckets exist,
checkpoint completion and restoration are verified, and connectors are packaged.

Before any jobs exist, revert the session declaration and explicitly sync its
removal. Keep CRDs and Operator while Flink resources exist. Once jobs exist,
verified savepoints and an approved restore plan are mandatory before removal.
Escalate failures to the repository owner; never use stateless fallback to hide
failed state recovery.

## Business-job migration blockers

All five legacy manifests point to an Operator image, use invalid schema fields,
and lack verified application images. Four Dockerfiles use a suspect base digest
and inconsistent COPY paths; the trading image contains Java and a JAR but no
Flink installation. Repair these in the application repository, include provided
Kafka/JDBC connectors, then verify each job's configuration, source offsets,
sink idempotency, checkpoints and savepoint restoration before cutover.

## Validation evidence (2026-09-07)

Root and runtime Kustomize rendering, official Operator chart rendering, root
and Operator client validation, and whitespace checks passed. Runtime server
validation passed. Live REST reported flink-version 1.18.1 (commit a8c8b1c),
one TaskManager and two available slots. Operator, JobManager and TaskManager
were Ready with zero restarts; FlinkDeployment reached STABLE / READY.
Bundled WordCount completed with FINISHED, two finished tasks, no failed tasks,
JobID 7555b3465d9dc7fa5dbbf4971863c353, runtime 5095 ms. Its CLI printed a
Log4j reconfiguration warning; job execution succeeded. No business jobs were
submitted and durable-state recovery has not been validated.

The first native session was verified empty (`jobs: []`) and retired through
GitOps before standalone creation because mode changes are not supported in
place. Explicit sync requests must include CreateNamespace=true and
ServerSideApply=true. CRD defaulting differences are compared using Argo CD
ServerSideDiff; no schema paths are ignored.

## Approved job scope (2026-09-07)

Only `eth-sentiment-trading-job` is selected for migration. The other four
modules are retired and must not be migrated. See
[the scope decision](../design/2026-09-07-flink-job-scope.md).

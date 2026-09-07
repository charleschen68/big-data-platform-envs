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
inspect Operator logs and FlinkDeployment status. JobManager process recovery now uses Kubernetes HA metadata and S3 state.
Single-node loss remains outside the recovery guarantee. Business jobs still
require packaged connectors, approved models and end-to-end recovery acceptance.

Before any jobs exist, revert the session declaration and explicitly sync its
removal. Keep CRDs and Operator while Flink resources exist. Once jobs exist,
verified savepoints and an approved restore plan are mandatory before removal.
Escalate failures to the repository owner; never use stateless fallback to hide
failed state recovery.

## Business-job migration blockers

Only eth-sentiment-trading-job remains in migration scope; the other four are
retired. Its old image contains Java and a JAR but no Flink installation. Package
the required connectors and verify the selected job's configuration, source
offsets, sink idempotency and recovery before cutover. Its hardcoded sentiment
and embedding models were absent from the live model inventory on 2026-09-07;
model and endpoint selection is awaiting the owner. Existing async functions
can drop records on failures, and Milvus writes need replay/idempotency review.

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

## Persistent state acceptance (2026-09-07)

Storage: bucket `flink-state`, scoped MinIO account `flink-state-runtime`,
SOPS Secret `flink-state-secrets` in namespace flink. The runtime uses the bundled
S3 Presto 1.18.1 plugin, retained externalized checkpoints and Kubernetes HA.
Account provisioning created only the new bucket/account/policy; no root
credential is passed to Flink. Preserve these resources during rollback.

Synthetic acceptance source: `scripts/flink-recovery/CounterRecovery.java`.
The independent source and keyed counters must match; a mismatch fails the job.

- Initial job: `66379a01cc6041fff7cda2e127db6fe2`.
- TaskManager recreation restored checkpoint 4; source counter resumed at 777.
- JobManager recreation recovered the same JobID from checkpoint 6, followed by
  further completed checkpoints with no checkpoint failures in the observation.
- Stop-with-savepoint produced
  `s3://flink-state/session/savepoints/savepoint-66379a-7673ea491971`.
- New job `dbaf2670d3f2f22f7e763ebaaa7fc10d` restored that exact path with
  `is_savepoint=true`, resumed at 4210, and completed six subsequent checkpoints
  with zero checkpoint failures at the acceptance observation.
- The CLI printed a Log4j configuration warning and one asynchronous Fabric8
  closed-classloader exception during client shutdown after submission. The
  server-side job remained RUNNING and checkpointing. Do not disable classloader
  checks; track client lifecycle separately from runtime state acceptance.

These are process-failure and explicit savepoint-restore tests on local MinIO.
No off-node backup, total-node-loss recovery, Kafka offset cutover or business
sink exactly-once guarantee has been validated.

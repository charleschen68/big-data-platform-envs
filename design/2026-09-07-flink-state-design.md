# Flink persistent state and recovery

## Context and authorization
The user selected persistent state/recovery and only eth-sentiment-trading-job
for migration. Other job modules are retired per the scope decision.
Owner: repository owner. Target: orbstack / flink; local single-node environment.

## Decision
Use an isolated MinIO bucket flink-state and account flink-state-runtime,
restricted to bucket listing/location and object read/write/delete/multipart
operations in this bucket. SOPS encrypts the credential before it is persisted.
The runtime receives AWS credentials through Secret environment references.
Enable the bundled Flink 1.18.1 S3 Presto plugin, filesystem checkpoint storage,
retained externalized checkpoints, savepoints and Kubernetes HA metadata.
Keep one JobManager: process recovery is provided, not multi-node availability.
MinIO local-path storage remains a node-loss risk; this is not an off-node backup.

## Rollout and rollback
Provision only the new bucket/account; no existing bucket or credential rotation.
Sync the new KSOPS Secret Application before changing the empty Flink session.
Run a synthetic stateful job, verify checkpoints and a savepoint, restart its
TaskManager and JobManager separately, and verify restoration from state.
No business job may be started while its model configuration is unresolved.
Rollback runtime configuration through GitOps only after stopping the test job;
retain all bucket objects and encrypted credentials. Never delete HA ConfigMaps
or storage to make a failed restore appear healthy.

## Validation
Render, server validate, verify scoped storage access, then test runtime recovery.
Record actual job IDs, checkpoint locations and recovery outcomes in the runbook.
Job correctness, Kafka offsets and external sink idempotency need separate
business acceptance; synthetic recovery cannot prove those contracts.

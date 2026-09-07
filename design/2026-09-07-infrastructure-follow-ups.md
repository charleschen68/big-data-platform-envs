# Infrastructure follow-ups

Scope: repository inspection and local observations on 2026-09-07. Owner:
repository owner. These are prioritized findings, not completed improvements.

| Priority | Finding | Acceptance criterion |
| --- | --- | --- |
| P0 | Five legacy Flink jobs lack runnable images and valid manifests | Reproducible 1.18.1 images with required connectors, per-job config, checkpoint and restore evidence before cutover |
| P0 | New session runtime has no durable state or HA recovery | SOPS-managed least-privilege S3 credentials, verified buckets, checkpoints, savepoint restore and source/sink reconciliation |
| P1 | Live GitOps follows feat/gitops-data-collectors while local main has extra replica edits | Review rendered differences and consolidate source branch without unintended scale changes |
| P1 | No repository CI workflow | Render every child overlay, Helm charts and CRD schemas; policy and secret checks on PRs |
| P1 | Single-node local-path storage and single Kafka replica | Explicit local-only availability contract; tested off-node backup and restore, measured RPO/RTO |
| P1 | verify-recovery.sh prints listings rather than asserting recovery and uses latest Kafka image | Noninteractive bounded checks fail on unavailable services, stale data and failed state restore |
| P1 | Mutable image references remain, including mysql:8.0 | Pin immutable digests and record upgrade/rollback evidence |
| P1 | No Flink checkpoint/freshness alerts in current overlay | Alerts for checkpoint failure, restart loops, lag, freshness and recovery duration with owner and runbook |
| P2 | Historical Instructions.md calls the existing standards file forthcoming | Reconcile documentation scope and validation evidence |

Changes to availability, backups and branch ownership require their own design,
rollout and rollback review. Runtime REST health alone is not job acceptance.

## Approved job scope (2026-09-07)

Only `eth-sentiment-trading-job` is selected for migration. The other four
modules are retired and must not be migrated. See
[the scope decision](2026-09-07-flink-job-scope.md).

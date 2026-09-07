# Infrastructure follow-ups

Scope: repository inspection and local observations on 2026-09-07. Owner:
repository owner. These are prioritized findings, not completed improvements.

| Priority | Finding | Acceptance criterion |
| --- | --- | --- |
| P0 | Selected trading job lacks a verified application image; four other jobs retired | Reproducible 1.18.1 trading image, approved models, error handling, connector and end-to-end recovery acceptance before cutover |
| P0 | Synthetic S3 checkpoint/savepoint and process HA recovery passed; business recovery remains unverified | Complete selected-job source/sink reconciliation and off-node backup/restore; retain evidence |
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

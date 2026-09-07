# Flink job migration scope

Decision date: 2026-09-07. Owner: repository owner.
Authority: user explicitly selected job 1 only and requested the other jobs be
marked not migrating and retired. This record supersedes the earlier five-job
migration inventory.

| Module | Decision | Deployment policy |
| --- | --- | --- |
| eth-sentiment-trading-job | Selected for migration | Deploy only after image, dependencies, persistent state and recovery acceptance |
| eth-sentiment-analysis-job | Retired; do not migrate / 废弃、不迁移 | Keep source for history; no new deployment |
| realtime-riskcontrol-embedding-job | Retired; do not migrate / 废弃、不迁移 | Keep source for history; no new deployment |
| employee-message-processor | Retired; do not migrate / 废弃、不迁移 | Keep source for history; no new deployment |
| kafka2milvus | Retired; do not migrate / 废弃、不迁移 | Keep source for history; no new deployment |

Retired means excluded from the active migration and deployment path. It does
not authorize deleting historical source, business data, Kafka topics or Milvus
collections. Any already-running legacy instance requires its own stop/state
inventory before retirement is represented as operationally complete.

## Selected job acceptance

- Use Flink 1.18.1, Java 17, pinned application image and packaged connectors.
- Verify Kafka input/output topics, consumer group, MySQL trade.eth_kline_features,
  Milvus collection/schema and both LLM/embedding endpoints and models.
- Preserve the source-start and signal contracts. Do not change consumer offsets
  or introduce a new group as a shortcut around state migration.
- Provide at least four slots for the existing four slot-sharing groups at
  parallelism one, or separately review a change to those groups.
- Verify checkpoint and savepoint persistence and restored processing state.
- Treat error swallowing and non-idempotent external writes as migration blockers;
  checkpoint completion alone does not establish loss-free end-to-end recovery.

## Rollback

Retain the current empty session runtime while prerequisites are being fixed.
Before a live trading-job cutover, record a recoverable savepoint or an explicit
fresh-start offset decision, ensure one active writer, and define rollback to
that exact state. Do not run retired jobs for migration testing.

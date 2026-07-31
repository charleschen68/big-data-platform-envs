# Production Engineering Standards

## Scope and Enforcement

These requirements govern every change to this GitOps environment repository.
`MUST`, `MUST NOT`, `SHOULD`, `SHOULD NOT`, and `MAY` are normative terms.
Exceptions MUST follow [the exception contract](README.md), be time-bounded,
and be approved before deployment.

## GitOps Change Management

Changes MUST be declarative, peer-reviewed, traceable to a commit, and applied
through the approved GitOps path. Each disruptive change MUST document rollout,
rollback, owner, affected scope, and post-deployment verification. Image tags
MUST be immutable; an exception MUST identify the compensating control.

> 变更必须可审查、可追溯，并通过批准的 GitOps 流程发布。

## Kubernetes Workload Requirements

Workloads MUST define CPU and memory requests and limits, run as non-root
where the workload permits it, and use the least privilege required. They MUST
have probes appropriate to their startup and runtime behavior. Availability,
storage, and disruption assumptions MUST be explicit for stateful services.

## Secrets and Supply-Chain Security

Secret material MUST be encrypted with SOPS and age before it enters version
control. Plaintext credentials, private keys, tokens, decrypted manifests, and
secrets in logs or documentation are prohibited. Dependencies and container
images MUST have a known source and a reproducible version reference.

> 禁止在仓库、日志或文档中出现明文密钥；密钥必须经 SOPS 加密。

## Observability and Operations

Production services MUST expose actionable health, metrics, and logs. Alerts
MUST identify an owner, severity, symptom, and first response. Runbooks MUST
state scope, prerequisites, expected results, failure signals, and escalation.

## Reliability, Backup, and Recovery

Stateful data MUST have a defined backup mechanism and recovery objective.
Restore and disaster-recovery procedures MUST be tested on a defined cadence
and record the result. Destructive operations MUST require explicit approval,
a verified backup or stated exception, a rollback or recovery path, and
post-operation verification.

> 破坏性操作前必须明确审批、备份、恢复路径和验证结果。

## Validation and Review

Every change MUST run proportionate validation before merge and retain the
evidence in the review. Manifest, policy, and documentation changes MUST be
checked for syntax, references, and unintended diff content. Reviewers MUST
block changes with unbounded blast radius, missing rollback, or unencrypted
secret material.

> 合并门禁必须包含与变更风险相匹配的验证证据。

## Documentation Requirements

Meaningful changes MUST update the applicable design record and runbook.
Documents MUST name owners, assumptions, scope, operational impact, and
failure handling. Commands MUST state prerequisites and expected outcomes;
unvalidated procedures MUST NOT be represented as production instructions.

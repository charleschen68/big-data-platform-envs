# Flink 1.18.1 GitOps migration

## Context
The OrbStack GitOps cluster has no Flink CRDs or jobs. The separate k3s-node
cluster contains legacy manifests and is not the deployment target.

## Constraints
Preserve existing data and collectors. Pin Flink to 1.18.1 / Java 17 by digest.
Legacy job images are not runnable Flink distributions and are excluded until repaired.

## Decision
Install the official Operator 1.9.0 chart and its structural CRDs in a separate
manual-sync Application, scoped to namespace flink. Deploy a standalone session cluster
through a second manual-sync Application. This is runtime infrastructure only;
five legacy application jobs require separate image and state acceptance.
Disable the chart webhook for this local environment because cert-manager is absent;
CRD validation and Operator reconciliation remain enabled. This local exception
expires before any production use. Operator 1.9.0 is a compatibility baseline,
not a claim of current upstream support. Upgrade assessment is required before production.

## Alternatives
Copying the legacy permissive CRDs and Operator image into jobs is invalid.
Direct kubectl deployment would create a second source of truth.

## Assumptions
Single-node local development, no availability guarantee. S3 checkpoint/savepoint storage and Kubernetes HA process recovery were added
and synthetically verified later on 2026-09-07; see the persistent-state design.
Business cutover remains gated on its own correctness and dependency acceptance.

## Operational Impact
One Operator, one JobManager and one resident TaskManager; two task slots.
Standalone mode makes taskManager.replicas effective even without submitted jobs.
No existing consumer groups or sinks are activated by this runtime deployment.

## Ownership
Repository owner operates the local environment and approves business-job cutover.

## Risk and Failure Modes
Node loss interrupts all workloads. Session restart loses submitted jobs without
HA metadata. Old application images lack runtime/dependencies. Do not interpret
REST health as checkpoint or end-to-end job acceptance.

## Rollout
Validate, commit to the live GitOps source branch, sync Operator, wait for CRDs
and controller readiness, then sync runtime. User explicitly authorized deployment.

## Rollback
Before jobs are submitted, delete only the flink-session resource through GitOps.
Keep Operator CRDs; never prune CRDs while any Flink resources exist. Once jobs
exist, obtain a verified savepoint and a restore plan before deleting or changing runtime.

## Verification
Render root, official Helm chart and runtime; client/server validation where
available. Verify REST reports 1.18.1, registered TaskManager and two slots.
Live results are recorded in the runbook.

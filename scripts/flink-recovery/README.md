# Flink state recovery acceptance

Owner: repository owner. Target: `orbstack`, namespace `flink`, `flink-session`.
This synthetic job checks a monotonically increasing source counter against
independently checkpointed keyed state. It does not consume Kafka or write to
business sinks. Stable operator UIDs allow savepoint restoration.

Prerequisites: Java 17, Flink 1.18.1 Maven dependencies, kubectl, healthy session,
S3 credentials and storage, and explicit authorization to interrupt the test
JobManager and TaskManager. First verify no other running jobs share the session.
Do not run fault injection against an unknown or business-occupied session.

Build `CounterRecovery.java` with Flink 1.18.1 core, java, runtime, streaming-java
and clients JARs on the compiler classpath; package with main class CounterRecovery.
Copy the resulting JAR to `/tmp/flink-recovery.jar` in the current JobManager.
Submit with `/opt/flink/bin/flink run -d -m localhost:8081 /tmp/flink-recovery.jar`.
Record the returned job ID; do not select an arbitrary running job.

Acceptance sequence:

1. Query `/jobs/<id>/checkpoints` until a completed checkpoint has an external
   path under `s3://flink-state/session/checkpoints/` and nonzero state size.
2. Delete only the observed TaskManager Pod. Verify a new Pod UID, RUNNING job,
   `latest.restored` checkpoint path and `RECOVERY_STATE_RESTORED next=N` with N>0.
3. After another checkpoint completes, delete only the observed JobManager Pod.
   Verify the same job ID recovers automatically with the restored checkpoint
   and both operators RUNNING. Never delete the FlinkDeployment or HA ConfigMaps.
4. Use `flink stop -p s3://flink-state/session/savepoints <id>` (no drain) and
   capture the returned savepoint path. Verify the old job reaches FINISHED.
5. Copy the JAR into the new JobManager if necessary; submit with
   `flink run -d -s <savepoint-path> -m localhost:8081 /tmp/flink-recovery.jar`.
   Verify `latest.restored.is_savepoint=true`, the exact savepoint path,
   RUNNING tasks and a subsequent successful checkpoint.
6. Cancel only the newly submitted test job by its recorded ID. Verify no jobs
   remain RUNNING and all slots become available. Retain savepoint evidence;
   deletion of stored state is a separate action.

A sequence mismatch must fail the job. A successful restart alone is not a pass.
These tests establish synthetic state restoration, not exactly-once business
side effects, Kafka cutover correctness, node-loss recovery or off-node backup.

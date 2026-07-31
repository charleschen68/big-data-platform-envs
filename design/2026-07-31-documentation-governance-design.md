# Documentation Governance Design

**Date:** 2026-07-31  
**Status:** Approved

## Purpose

Establish a production-grade documentation baseline for this GitOps environment
repository. The documentation must let an engineer or automation agent make a
safe change, operate the platform, and understand the governing engineering
requirements without relying on tribal knowledge.

English is the authoritative language. Chinese annotations are included for
operationally important requirements so that intent is unambiguous to the
primary team. If translations conflict, the English requirement prevails until
the document is corrected in the same change.

## Information Architecture

```text
Instructions.md
design/
  README.md
  YYYY-MM-DD-<topic>-design.md
wiki/
  README.md
standards/
  README.md
  engineering-standards.md
```

`Instructions.md` is the repository entry point. It defines the mandatory
contribution workflow, document ownership, and links to the remaining areas.

`design/` is the durable decision and system-design record. Each meaningful
change has a dated design document that states context, constraints, chosen
approach, alternatives, failure modes, rollout, verification, and rollback.

`wiki/` is the operational knowledge base. It contains runbooks, recovery
procedures, troubleshooting guides, and component operating procedures. It is
not a duplicate of environment declarations.

`standards/` is the normative policy set. `engineering-standards.md` provides
mandatory requirements for GitOps, Kubernetes manifests, secrets, observability,
reliability, testing, documentation, and review. Requirements use RFC 2119
terms (MUST, SHOULD, MAY).

## Required Content

The standards document must require:

- declarative GitOps changes with reviewed, traceable rollout and rollback;
- SOPS-encrypted secrets only, with no plaintext credentials in version
  control, rendered manifests, logs, or documentation;
- explicit resource requests and limits, security context, probes, and
  availability considerations for workload manifests;
- actionable monitoring, alerts, backup, recovery, and disaster-recovery
  verification;
- scoped validation before merge and post-deployment verification for
  disruptive changes;
- documented ownership, assumptions, operational impact, and failure handling.

## Error Handling and Safety

Documentation must fail safely: commands must state prerequisites, scope, and
expected outcomes; destructive or disruptive procedures must state approval,
backup, verification, and rollback conditions. Procedures must never instruct
users to expose plaintext secrets.

## Verification

The documentation baseline is accepted when all required paths exist, internal
links resolve, the standards contain no placeholders, terminology is consistent
with the current repository structure, and repository status shows only the
intended documentation files (apart from pre-existing untracked `.DS_Store`
files).

## Explicit Non-Goals

- Introducing a documentation-site generator or new runtime dependency.
- Replacing component-specific deployment documentation already held upstream.
- Writing hypothetical runbooks that have not been validated against this
  environment.

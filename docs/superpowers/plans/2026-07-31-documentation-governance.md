# Documentation Governance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a production-grade bilingual documentation baseline for safe GitOps work.

**Architecture:** `Instructions.md` is the repository entry point. The `design/`, `wiki/`, and `standards/` directories respectively hold decision records, operational knowledge, and normative requirements; links use relative Markdown paths and introduce no runtime dependencies.

**Tech Stack:** Markdown, Git, Kubernetes, Argo CD, Kustomize, Helm, SOPS, age, Velero.

## Global Constraints

- English is authoritative; Chinese text supplements critical operational requirements.
- Requirements use RFC 2119 terms: MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY.
- Never include plaintext credentials, private keys, decrypted manifests, or cluster-specific tokens.
- Keep the existing `environments/current/` and `scripts/` topology unchanged.
- Do not add a documentation-site generator or runtime dependency.

---

### Task 1: Create entry point and documentation indexes

**Files:**
- Create: `Instructions.md`
- Create: `design/README.md`
- Create: `wiki/README.md`
- Create: `standards/README.md`

**Interfaces:**
- Consumes: `README.md` repository topology and the approved governance design.
- Produces: the navigable documentation entry point and three bounded documentation areas.

- [ ] **Step 1: Verify the expected files are initially absent**

Run: `test -f Instructions.md && test -f design/README.md && test -f wiki/README.md && test -f standards/README.md`

Expected: non-zero exit status before creating the files.

- [ ] **Step 2: Write the four focused documents**

`Instructions.md` must link to `README.md`, `design/README.md`, `wiki/README.md`, and `standards/engineering-standards.md`; define the mandatory workflow as design, change, validate, review, deploy, and observe; and prohibit plaintext secrets.

`design/README.md` must define a record template with `Context`, `Decision`, `Alternatives`, `Risk and Failure Modes`, `Rollout`, `Rollback`, and `Verification`.

`wiki/README.md` must require runbooks to state prerequisites, permissions, impact, commands, expected results, failure signals, rollback or escalation, and validation date.

`standards/README.md` must designate `engineering-standards.md` as normative and require exceptions to name an owner, expiry date, and compensating control.

- [ ] **Step 3: Verify the files and links**

Run: `test -f Instructions.md && test -f design/README.md && test -f wiki/README.md && test -f standards/README.md && rg -n '\]\((README\.md|design/README\.md|wiki/README\.md|standards/engineering-standards\.md)\)' Instructions.md`

Expected: all files exist and the four targets are printed.

- [ ] **Step 4: Commit the entry point and indexes**

Run: `git add Instructions.md design/README.md wiki/README.md standards/README.md && git commit -m "docs: add documentation entry points"`

### Task 2: Establish the normative engineering standard

**Files:**
- Create: `standards/engineering-standards.md`

**Interfaces:**
- Consumes: the workflow in `Instructions.md` and exception contract in `standards/README.md`.
- Produces: requirements for contributors, reviewers, and runbook authors.

- [ ] **Step 1: Verify the standard is absent**

Run: `test -f standards/engineering-standards.md`

Expected: non-zero exit status before creation.

- [ ] **Step 2: Write enforceable standard sections**

Include these exact sections: `Scope and Enforcement`, `GitOps Change Management`, `Kubernetes Workload Requirements`, `Secrets and Supply-Chain Security`, `Observability and Operations`, `Reliability, Backup, and Recovery`, `Validation and Review`, and `Documentation Requirements`.

Require reviewed declarative changes, immutable image references or a documented exception, resource requests and limits, least privilege and non-root execution, appropriate probes, SOPS-encrypted secrets, no credentials in logs or docs, owned actionable alerts, recovery testing, rollback and post-deployment checks, and review evidence. Add Chinese annotations for secret handling, destructive operations, recovery, and merge gates.

- [ ] **Step 3: Verify headings and key controls**

Run: `for heading in 'Scope and Enforcement' 'GitOps Change Management' 'Kubernetes Workload Requirements' 'Secrets and Supply-Chain Security' 'Observability and Operations' 'Reliability, Backup, and Recovery' 'Validation and Review' 'Documentation Requirements'; do rg -F "## $heading" standards/engineering-standards.md; done && rg -n 'MUST NOT.*plaintext|SOPS|rollback|restore|resource requests|resource limits' standards/engineering-standards.md`

Expected: every heading and safety control is printed.

- [ ] **Step 4: Commit the standard**

Run: `git add standards/engineering-standards.md && git commit -m "docs: define production engineering standards"`

### Task 3: Validate the complete documentation baseline

**Files:**
- Modify: `Instructions.md`
- Modify: `design/README.md`
- Modify: `wiki/README.md`
- Modify: `standards/README.md`
- Modify: `standards/engineering-standards.md`

**Interfaces:**
- Consumes: all documentation created by Tasks 1 and 2.
- Produces: a link-complete, consistent, placeholder-free documentation baseline.

- [ ] **Step 1: Add the validation contract to `Instructions.md`**

Add a `Documentation validation` section requiring `rg -n 'TODO|TBD|FIXME' Instructions.md design wiki standards`, `git diff --check`, and `git status --short`. Clarify that template labels in a design index must be replaced in actual records.

- [ ] **Step 2: Run validation**

Run: `rg -n 'TODO|TBD|FIXME' Instructions.md design wiki standards || true; git diff --check; git status --short`

Expected: no unintentional placeholders or whitespace errors; only intended documentation files and pre-existing `.DS_Store` files appear.

- [ ] **Step 3: Correct concrete validation failures and rerun**

Correct broken relative links, unintended placeholders, or inconsistent terminology. Then run: `for file in Instructions.md design/README.md wiki/README.md standards/README.md standards/engineering-standards.md; do test -s "$file"; done; git diff --check; git status --short`

Expected: all required files are non-empty and there are no whitespace errors.

- [ ] **Step 4: Commit the verified baseline**

Run: `git add Instructions.md design/README.md wiki/README.md standards/README.md standards/engineering-standards.md && git commit -m "docs: complete documentation governance baseline"`

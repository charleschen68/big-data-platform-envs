# Documentation Instructions

This file is the documentation entry point for this GitOps environment
repository. Start with the repository topology in [README.md](README.md), then
use the bounded documentation areas below:

- [Design records](design/README.md) capture durable decisions and change
  design.
- [Operational wiki](wiki/README.md) contains validated runbooks and recovery
  procedures.
- [Standards index](standards/README.md) explains the normative policy area.
- The forthcoming [engineering standards](standards/engineering-standards.md)
  will contain the normative requirements for this repository; this planned
  target is not yet present in Task 1.

English is authoritative. Chinese annotations clarify critical operational
requirements; if a translation conflicts with English, correct the document in
the same change.

The owner of a component or change owns its design record, operational
documentation, and any associated exception. Reviewers MUST confirm that these
documents remain accurate before approving a change.

## Mandatory workflow

Every meaningful change MUST follow this sequence: **design, change, validate,
review, deploy, and observe**. Record the decision before implementation,
validate the scoped change before review, use the approved deployment path, and
observe the result after deployment. Do not skip rollback planning for a
disruptive change.

No plaintext secrets, credentials, tokens, or keys may be committed, rendered
into manifests, copied into logs, or documented in this repository.

> 严禁以明文形式提交、记录或复制密码、令牌、密钥等敏感信息。

## Documentation validation

Before requesting review, run the scoped checks below. Replace template labels
in `design/README.md` with concrete content in every actual design record.

```bash
rg -n 'TODO|TBD|FIXME' Instructions.md design wiki standards
git diff --check
git status --short
```

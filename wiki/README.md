# Operational Wiki

`wiki/` contains validated runbooks, recovery procedures, troubleshooting
guides, and component operating procedures. It does not duplicate environment
declarations.

Every runbook MUST state:

- prerequisites;
- required permissions;
- scope and affected targets;
- operational impact;
- commands;
- expected results;
- failure signals;
- rollback or escalation; and
- validation date.

For disruptive or destructive actions, also state the required approval,
backup condition, and verification before execution. Never instruct an operator
to expose plaintext secrets.

> 运维手册必须明确前提条件、权限、影响、验证和回滚或升级路径。

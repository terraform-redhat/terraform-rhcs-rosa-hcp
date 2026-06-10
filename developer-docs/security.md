# Security

WHEN editing Terraform, **`examples/`**, or tests:
- MUST NOT: Hard code secrets or long-lived AWS keys — use STS/OIDC/IRSA patterns from **`examples/`**.
- MUST: `sensitive = true` on secrets in variables and outputs.
- MUST: Parent passthrough outputs match child sensitivity (`module.*` → root output).
- MUST NOT: Expose credentials in logs, debug locals, outputs, or comments.
DEFAULT: For Gitleaks, Checkov, or Dockerfile changes — see [`AGENTS.md`](../AGENTS.md).

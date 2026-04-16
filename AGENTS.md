# Agent guide — terraform-rhcs-rosa-hcp

This repository is the **ROSA HCP** Terraform module. The sibling **ROSA Classic** module is [`terraform-rhcs-rosa-classic`](https://github.com/terraform-redhat/terraform-rhcs-rosa-classic) — do not mix architectures.

## Where rules live

| File | Purpose |
|------|--------|
| [`.cursor/rules/`](.cursor/rules/) | Hard, stable guardrails (architecture boundaries, provider/version constraints, variable conventions, credentials/secrets) |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Command and procedure authority (fmt, verify, docs generation, test execution) |
| This file | Process narrative, security expectations, and decision workflow for agents |

Thin entrypoints [`CLAUDE.md`](CLAUDE.md) and [`GEMINI.md`](GEMINI.md) only point here so we do not duplicate content.

## HashiCorp Terraform skills

Upstream skills live under:

**https://github.com/hashicorp/agent-skills/tree/main/terraform**

Important: if you encounter a conflict between the skills below and this repository’s `CONTRIBUTING.md`, `CONTRIBUTING.md` takes precedence.

Useful skills for this codebase:

| Skill | When to use |
|-------|-------------|
| **terraform-style-guide** | Formatting HCL, variable/output layout, naming |
| **terraform-test** | Adding or changing `*.tftest.hcl`, mocks, `terraform test` |
| **refactor-module** | Splitting modules, clarifying interfaces, safe refactors |

**How to use them**

1. Open the skill’s `SKILL.md` in the repo (or your local skills mirror).
2. Apply its workflow to the task (style, tests, or refactor) instead of inventing patterns.
3. Still respect this repository’s `CONTRIBUTING.md` and **root `versions.tf`** constraints.

## Provider & versions

- [`terraform-redhat/rhcs`](https://github.com/terraform-redhat/terraform-provider-rhcs) defines resource schemas — mirror them in variables and docs.
- Root **`versions.tf`** = effective minimum **rhcs** and **aws** for **all** submodules; bump root when any submodule needs a newer provider.

## Architecture reference

- [AWS — ROSA vs HCP vs Classic](https://docs.aws.amazon.com/rosa/latest/userguide/rosa-architecture-models.html#rosa-architecture-differences)

## Security

**Canonical baseline** (must / must-not): [`.cursor/rules/rosa-hcp-terraform.mdc`](.cursor/rules/rosa-hcp-terraform.mdc) — section **Security**. If anything below conflicts with that file or with **`CONTRIBUTING.md`**, follow those sources.

**Agent-oriented checks** when editing Terraform, **`examples/`**, and tests:

- Do **not** hardcode secrets, API keys, or long-lived AWS access keys in Terraform, examples, or tests. Prefer patterns in existing **`examples/`** and Red Hat documentation (STS, OIDC, IRSA, short-lived credentials).
- Use **`sensitive`** on variables and outputs where values must not appear in logs or casual `terraform show` output; avoid echoing secrets in `local` values used only for debugging. Passthrough outputs (**`module.*` → root output**) must match submodule sensitivity—see **Security** in [`.cursor/rules/rosa-hcp-terraform.mdc`](.cursor/rules/rosa-hcp-terraform.mdc).
- Do not add logging, outputs, or comments that expose credentials or session tokens.

## Trivy (IaC misconfiguration)

Repo config: root **`trivy.yaml`** (severity, scanners, skips; includes **`examples/`**). CodeRabbit may run Trivy when enabled in **`.coderabbit.yaml`**. References: [Trivy config file](https://trivy.dev/latest/docs/references/configuration/config-file/), [filtering / ignores](https://trivy.dev/latest/docs/configuration/filtering/).

When **`trivy config`** reports a **misconfiguration** (check IDs like **`AWS-0104`**, **`DS-0002`** — not CVE vulnerability rows from **`trivy fs`** vuln scans):

1. **Prefer fixing** the HCL/Dockerfile (least privilege, encryption, IMDSv2, non-root user, etc.).
2. If an ignore is required, add **`#trivy:ignore:<id>`** on the line **immediately above** the Terraform resource or Dockerfile instruction, with a **short `#` comment** on the same line or the line above explaining why (narrow scope).
3. Use **`.trivyignore`** only when inline suppression is not possible — one ID per line with a **`#` justification** above each.
4. **Dockerfile `DS-0002`:** Inline `#trivy:ignore` is not reliably applied by Trivy for this rule; prefer **`USER` with a non-root account** after root-only install steps (see root `Dockerfile`).

## Critical Module Guardrails

- Breaking Changes: Do NOT change existing variable names or types without a migration plan (refactor-module skill).
- HCP Specifics: Always verify if a feature is supported in HCP vs. Classic. If the `rhcs` resource type does not include `_hcp`, double-check the provider docs.

## Module scope (AWS-only configuration)

Not every AWS resource belongs in this repo. **When to add or expand AWS-only modules** vs leaving configuration to users is defined in [`.cursor/rules/rosa-hcp-terraform.mdc`](.cursor/rules/rosa-hcp-terraform.mdc) — section **Module scope (AWS-only vs core HCP)**. Favor **reference-documented**, **error-prone-if-DIY**, and **testable** patterns; defer **optional, customer-variable** AWS glue that official docs do not prescribe.

## Workflow Logic for Agents

When asked to add a feature, the agent should follow this internal loop:

1. Verify Provider Support: Check the provider schema/docs for the version range in root versions.tf.
2. Check versions.tf: Does this require a provider bump? If yes, modify the root versions.tf first.
3. **Module scope:** For new or expanded **AWS-only** behavior, confirm it meets **Module scope (AWS-only vs core HCP)** in [`.cursor/rules/rosa-hcp-terraform.mdc`](.cursor/rules/rosa-hcp-terraform.mdc); prefer examples or user-owned Terraform when docs do not support in-repo ownership.
4. Variable Standard: Add variables using the description / type / default order. Ensure descriptions match the upstream provider docs.
5. Docs and tests: apply the required commands and verification steps from **`CONTRIBUTING.md`**.
6. Security: follow **Security** above (canonical rules in `.cursor/rules` first, then the agent-oriented bullets).

## Testing Expectations

New features should include a new `.tftest.hcl` file or an update to an existing one when module behavior changes.

Use mocks for AWS and RHCS resources to verify logic without requiring live credentials.

When module behavior branches on a **boolean variable** (e.g. **`count = var.x ? 1 : 0`**), prefer **more than one `run` block** (or clearly separated scenarios) so **both** outcomes are covered—typically **`true` / `count = 1`** and **`false` / `count = 0`**—not only the default or “happy” path. That avoids regressions where the positive case passes but the opt-out path breaks.

For exact commands and pass/fail criteria, follow **`CONTRIBUTING.md`**.
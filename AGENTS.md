# Agent guide — terraform-rhcs-rosa-hcp

This repository is the **ROSA HCP** Terraform module. The sibling **ROSA Classic** module is [`terraform-rhcs-rosa-classic`](https://github.com/terraform-redhat/terraform-rhcs-rosa-classic) — do not mix architectures.

## Where rules live

| File | Purpose |
|------|--------|
| [`.cursor/rules/`](.cursor/rules/) | Hard, stable guardrails (architecture boundaries, provider/version constraints, variable conventions, credentials/secrets) |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Command and procedure authority (fmt, verify, docs generation, test execution, commit format, changelog automation) |
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
- Root **`versions.tf`** declares the minimum **Terraform CLI** (currently **>= 1.5.7**) and the minimum **rhcs** and **aws** providers for **all** submodules.
- To prevent technical debt, Renovate automatically opens Pull Requests to bump these root constraints whenever a new provider version is released, keeping our baseline continuously updated.
- Submodule **`terraform test`** files under **`modules/*/tests/`** may use **`mock_provider`** and require a **newer** Terraform CLI than the module minimum (see **`CONTRIBUTING.md`**); CI runs tests with a pinned current release.

## Architecture reference

- [AWS — ROSA, HCP, and Classic comparison](https://docs.aws.amazon.com/rosa/latest/userguide/rosa-architecture-models.html#rosa-architecture-differences)

## Security

**Canonical baseline** (must / must-not): [`.cursor/rules/rosa-hcp-terraform.mdc`](.cursor/rules/rosa-hcp-terraform.mdc) — section **Security**. If anything below conflicts with that file or with **`CONTRIBUTING.md`**, follow those sources.

**Agent-oriented checks** when editing Terraform, **`examples/`**, and tests:

- Do **not** hard code secrets, API keys, or long-lived AWS access keys in Terraform, examples, or tests. Prefer patterns in existing **`examples/`** and Red Hat documentation (STS, OIDC, IRSA, short-lived credentials).
- Use **`sensitive`** on variables and outputs where values must not appear in logs or casual `terraform show` output; avoid echoing secrets in `local` values used only for debugging. Passthrough outputs (**`module.*` → root output**) must match submodule sensitivity—see **Security** in [`.cursor/rules/rosa-hcp-terraform.mdc`](.cursor/rules/rosa-hcp-terraform.mdc).
- Do not add logging, outputs, or comments that expose credentials or session tokens.

## CI client Dockerfile (Prow)

The root **`Dockerfile`** builds the **OpenShift Prow** client image (`terraform-rhcs-rosa-hcp-clients`). Treat it as a **minimal supply-chain surface**: include **only** what presubmit jobs in [`openshift/release`](https://github.com/openshift/release/tree/master/ci-operator/config/terraform-redhat/terraform-rhcs-rosa-hcp) need today (`make verify`, `make verify-gen`, `make run-example`, and the tools behind `make pre-push-checks`). The image pins the newest Terraform release (`TERRAFORM_VERSION`); module minimum compatibility is enforced separately by GitHub Actions **`verify-min-terraform.yml`** (see **`CONTRIBUTING.md`**).

When changing the Dockerfile:

- **Minimize attack surface** — prefer **`ubi-minimal`** with a **pinned** minor tag (not `:latest`); do not add OS packages, compilers, or CLIs “for convenience” without a job that uses them. The client image runs as **root** so Prow/ci-operator can write to the mounted repo workspace (`make verify`, `make verify-gen`); do not add a non-root `USER` without coordinating `openshift/release` workspace ownership.
- **Pin versions** — base image, ROSA CLI, and Makefile tools; use **`# renovate:`** comments and existing patterns (`hack/install-release-tool.sh` release binaries, not `go install`, unless unavoidable).
- **Avoid bloat** — the image is tool-heavy (Terraform, AWS CLI, ROSA, lint binaries); do not grow it with extra runtimes, caches, or unrelated utilities. Prefer release tarballs over full language SDKs in the final image.
- **Security scans** — `make security-check` is separate from `make pre-push-checks`; fix findings or document narrow suppressions per the **Gitleaks** and **Checkov** sections below.

## Gitleaks (secret detection)

Repo config: root **`.gitleaks.toml`** (extends default rules; allowlists `*.tftest` harness placeholders and `bin/` / `.terraform/` caches). Install with `make security-check-bin` or `make gitleaks`. `make security-check` runs **`gitleaks detect --no-git`** (current tree only, not git history) before Checkov. References: [Gitleaks README](https://github.com/gitleaks/gitleaks/blob/master/README.md).

When **`make security-check`** reports a Gitleaks finding, treat it as a real secret risk unless the match is a documented mock in test code covered by the allowlist. Do not commit credentials, tokens, or kubeconfigs; rotate anything that was exposed.

## Checkov (Terraform security)

Repo config: root **`checkov.yaml`** (framework, skip paths, **HIGH**/**CRITICAL** hard-fail). Install with `make security-check-bin`. `hack/install-release-tool.sh` verifies each Checkov zip against **`hack/checksums/checkov-<version>.sha256sums`** (upstream releases do not ship checksums — refresh that file when **`CHECKOV_VERSION`** changes). `make security-check` passes **`--skip-download`** so Checkov does not call Prisma Cloud (no `BC_API_KEY` required). **`modules/rosa-cluster-hcp/main.tf`** is skipped because Checkov cannot parse its multiline lifecycle preconditions (Terraform **`make verify`** still validates it). References: [Checkov CLI](https://www.checkov.io/2.Basics/CLI%20Command%20Reference.html).

When **`make security-check`** reports a finding (check IDs like **`CKV_AWS_*`**, **`CKV2_AWS_*`**):

1. **Prefer fixing** the HCL (least privilege, encryption, IMDSv2, etc.).
2. If a skip is required, add **`#checkov:skip=<CKV_ID>:<reason>`** on the line **immediately above** the flagged resource, with a short justification (narrow scope).
3. Use **`skip-check`** entries in **`checkov.yaml`** only when inline suppression is not possible — one ID per entry with a comment explaining why.
4. **Remove stale suppressions** — when code or Checkov no longer reports a check, delete the matching `#checkov:skip` comment or **`checkov.yaml`** `skip-check` entry so drift does not hide new findings.

## Critical Module Guardrails

- Breaking Changes: Do NOT change existing variable names or types without a migration plan (refactor-module skill).
- HCP Specifics: Always verify if a feature is supported in HCP compared to Classic. If the `rhcs` resource type does not include `_hcp`, double-check the provider docs.

## Module scope (AWS-only configuration)

Not every AWS resource belongs in this repo. **When to add or expand AWS-only modules** compared to leaving configuration to users is defined in [`.cursor/rules/rosa-hcp-terraform.mdc`](.cursor/rules/rosa-hcp-terraform.mdc) — section **`Module scope (AWS-only vs core HCP)`**. Favor **reference-documented**, **error-prone-if-DIY**, and **testable** patterns; defer **optional, customer-variable** AWS glue that official docs do not prescribe.

## Workflow Logic for Agents

When asked to add a feature, the agent should follow this internal loop:

1. Verify Provider Support: Check the provider schema/docs for the version range in root versions.tf.
2. Check versions.tf: Does this require a provider bump? If yes, modify the root versions.tf first.
3. **Module scope:** For new or expanded **AWS-only** behavior, confirm it meets **Module scope (AWS-only compared to core HCP)** in [`.cursor/rules/rosa-hcp-terraform.mdc`](.cursor/rules/rosa-hcp-terraform.mdc); prefer examples or user-owned Terraform when docs do not support in-repo ownership.
4. Variable Standard: Add variables using the description / type / default order. Ensure descriptions match the upstream provider docs.
5. Docs and tests: apply the required commands and verification steps from **`CONTRIBUTING.md`**.
6. Security: follow **Security** above (canonical rules in `.cursor/rules` first, then the agent-oriented bullets).

## Testing Expectations

New features should include a new `.tftest.hcl` file or an update to an existing one when module behavior changes.

Use mocks for AWS and RHCS resources to verify logic without requiring live credentials.

When module behavior branches on a **boolean variable** (e.g. **`count = var.x ? 1 : 0`**), prefer **more than one `run` block** (or clearly separated scenarios) so **both** outcomes are covered—typically **`true` / `count = 1`** and **`false` / `count = 0`**—not only the default or “happy” path. That avoids regressions where the positive case passes but the opt-out path breaks.

Before opening a PR, `make pre-push-checks` must pass locally; see **`CONTRIBUTING.md`** for commands and pass/fail criteria.

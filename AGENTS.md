# Agent guide — terraform-rhcs-rosa-hcp

Source of truth for AI assistants and review tooling (including CodeRabbit). Rules live in **`developer-docs/`**; commands in **`CONTRIBUTING.md`**.

ROSA HCP only — not [`terraform-rhcs-rosa-classic`](https://github.com/terraform-redhat/terraform-rhcs-rosa-classic).

## Where to look

| Topic | When to read | Doc |
|-------|--------------|-----|
| Architecture | Any change; HCP versus Classic; ROSA CLI parity | [`developer-docs/architecture.md`](developer-docs/architecture.md) |
| Providers and versions | Providers, floors, new AWS resources | [`developer-docs/providers-and-versions.md`](developer-docs/providers-and-versions.md) |
| Submodules | Adding or editing `modules/**` | [`developer-docs/submodules.md`](developer-docs/submodules.md) |
| Security | Secrets, `sensitive`, outputs | [`developer-docs/security.md`](developer-docs/security.md) |
| Variables | Adding or changing `variable` blocks | [`developer-docs/variables.md`](developer-docs/variables.md) |
| Commands and PR checks | Before opening a PR | [`CONTRIBUTING.md`](CONTRIBUTING.md) |

Entrypoints [`CLAUDE.md`](CLAUDE.md) and [`GEMINI.md`](GEMINI.md) point here.

## Skills

[HashiCorp terraform skills](https://github.com/hashicorp/agent-skills/tree/main/terraform) — **`CONTRIBUTING.md` wins** on conflict.

| Skill | When |
|-------|------|
| **terraform-style-guide** | HCL layout — see [`developer-docs/variables.md`](developer-docs/variables.md) |
| **terraform-test** | `*.tftest.hcl`, mocks |
| **refactor-module** | Module splits, breaking interface changes |

## Workflow

1. Check **rhcs** provider schema for root `versions.tf` range.
2. Provider bump? Update root `versions.tf` first — [`developer-docs/providers-and-versions.md`](developer-docs/providers-and-versions.md).
3. AWS-only submodule? — read in order: [`developer-docs/submodules.md`](developer-docs/submodules.md), [`developer-docs/variables.md`](developer-docs/variables.md), [`developer-docs/providers-and-versions.md`](developer-docs/providers-and-versions.md), [`developer-docs/architecture.md`](developer-docs/architecture.md). Then check the ROSA CLI source for any field the module validates. For each AWS resource created, fetch the provider documentation and apply all notes and warnings before implementing.
4. Variables? — read [`developer-docs/variables.md`](developer-docs/variables.md). For each variable that maps to a ROSA CLI-validated field (name, path, prefix, enum), verify the validation block against the CLI source before finishing.
5. Docs/tests/commands — [`CONTRIBUTING.md`](CONTRIBUTING.md).
6. Security — [`developer-docs/security.md`](developer-docs/security.md).

## Guardrails

- MUST NOT: Change variable/output names or types without a migration plan.
- MUST: Confirm HCP support — if `rhcs` resource lacks `_hcp`, check provider docs.
- Submodule **`terraform test`** may need a newer Terraform CLI than module minimum — see **`CONTRIBUTING.md`**.

## Testing

- MUST: Add or update `*.tftest.hcl` when module behavior changes.
- MUST: Mock AWS/RHCS — no live credentials in tests.
- MUST: Boolean branches — cover both outcomes (`true`/`count=1` and `false`/`count=0`).
- MUST: Validation blocks — add an `expect_failures` run for each `validation` block added.
- MUST: `make pre-push-checks` before PR — [`CONTRIBUTING.md`](CONTRIBUTING.md).

## CI Dockerfile (Prow)

WHEN editing root **`Dockerfile`**:

- MUST: Minimal surface — only what Prow presubmits need (`make verify`, `verify-gen`, `run-example`, `pre-push-checks` tools).
- MUST: Pin versions (UBI, AWS CLI, ROSA CLI, Terraform); `# renovate:` comments; release binaries via `hack/install-release-tool.sh`.
- MUST: Verify AWS CLI (`gpg --verify`) and ROSA CLI (`sha256sum -c`) per existing patterns.
- MUST NOT: Add packages/runtimes without a job that uses them.

## Gitleaks

WHEN `make security-check` reports a finding:

- MUST: Treat as real unless documented mock in allowlisted test code (`.gitleaks.toml`).
- Config: `.gitleaks.toml`; install: `make security-check-bin`.

## Checkov

WHEN `make security-check` reports **HIGH**/**CRITICAL**:

1. MUST: Fix HCL first (least privilege, encryption, IMDSv2).
2. MAY: `#checkov:skip=<ID>:<reason>` on line above resource (narrow scope).
3. MAY: `checkov.yaml` `skip-check` only when inline skip impossible.
4. MUST: Remove stale suppressions when checks no longer fire.

Config: `checkov.yaml`; `modules/rosa-cluster-hcp/main.tf` skipped (Checkov parse limit).

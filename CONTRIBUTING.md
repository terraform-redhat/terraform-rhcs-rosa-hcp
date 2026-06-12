# Contributing

Thanks for helping improve this module. Please open pull requests against **`main`**, and run through the short checklist below before you submit—whether you wrote the change yourself, paired with a tool, or used an AI assistant. It keeps reviews quick and consistent for everyone.

This repo is **ROSA HCP** only. The sibling **ROSA Classic** module is [`terraform-rhcs-rosa-classic`](https://github.com/terraform-redhat/terraform-rhcs-rosa-classic) — do not mix architectures, resources, or variable names between the two.

## AI assistants

| Location | Purpose |
|----------|---------|
| [`developer-docs/`](developer-docs/) | Tool-agnostic guardrails: architecture, providers, submodules, security, variables |
| [`AGENTS.md`](AGENTS.md) | Agent hub (links to **`developer-docs/`**), skills, workflow, testing expectations; commands live in **`CONTRIBUTING.md`** |
| [`CLAUDE.md`](CLAUDE.md), [`GEMINI.md`](GEMINI.md) | One-line pointers to [`AGENTS.md`](AGENTS.md) (names match Claude Code / Gemini CLI defaults) |

**HashiCorp Terraform skills** (optional reference when generating or refactoring HCL): [terraform skills in agent-skills](https://github.com/hashicorp/agent-skills/tree/main/terraform) — e.g. **terraform-style-guide**, **terraform-test**, **refactor-module**. If a skill conflicts with **`CONTRIBUTING.md`**, **`CONTRIBUTING.md`** takes precedence (see [`AGENTS.md`](AGENTS.md)).

## Before you open a PR

1. **Format** — `terraform fmt -recursive` (or format only dirs you changed).
2. **Validate** — `make verify` (runs `terraform init` + `validate` in each `examples/*` directory; compatible with the minimum Terraform version in root **`versions.tf`**, currently **>= 1.5.7**). Fix failures in examples you touch or that your change breaks.
3. **Docs** — If you changed variables, outputs, modules, or root wiring: run `make verify-gen` (runs `terraform-docs` via [`scripts/terraform-docs.sh`](scripts/terraform-docs.sh), then [`scripts/verify-gen.sh`](scripts/verify-gen.sh) to ensure README inject blocks are committed).
4. **Module tests** — If a submodule under `modules/<name>/tests/` has `*.tftest.hcl`, run `terraform init -backend=false && terraform test` from `modules/<name>/`, or run `make unit-tests` for all modules with tests.
5. **Documentation lint** — `make docs-lint` runs the pinned [Vale](https://docs.vale.sh/) CLI (release binary from [vale-cli/vale](https://github.com/vale-cli/vale)) with Red Hat documentation styles (see [`.vale.ini`](.vale.ini)).
6. **Variables** — Follow [`developer-docs/variables.md`](developer-docs/variables.md) (provider-aligned schemas, validation, naming, and layout).
7. **Submodules (AWS-only)** — If the change adds or expands **AWS-only** configuration (no `rhcs` surface), confirm it matches [`developer-docs/submodules.md`](developer-docs/submodules.md). In the PR, **link official Red Hat or cited ROSA HCP documentation** that supports shipping it in-repo, or explain why an exception is justified.

Run the full local verification flow (same steps as the planned single OpenShift Prow presubmit) with:

```shell
make pre-push-checks
```

`make pre-push-checks` runs `tools` (installs pinned CLI versions from the Makefile), then `verify`, `verify-gen`, `lint`, `unit-tests`, `license-check`, and `docs-lint` in order (fail-fast). Install tools alone with `make tools`. Run individual check targets when debugging one step. OpenShift Prow will use `make pre-push-checks` as the presubmit merge gate after `openshift/release` is updated (client image from the root [`Dockerfile`](Dockerfile) pins the newest Terraform release for integration jobs). GitHub Actions runs **`verify-min-terraform.yml`** on every PR to validate examples at the module minimum in root **`versions.tf`**. Run `make pre-push-checks` locally before opening a PR (use a Terraform version that satisfies **`versions.tf`** locally, or match the versions you need to debug).

**Security (separate from the merge gate):** `make security-check` runs [Gitleaks](https://github.com/gitleaks/gitleaks) secret detection on the **current tree** (`--no-git`; config: [`.gitleaks.toml`](.gitleaks.toml)) and [Checkov](https://www.checkov.io/) Terraform static analysis ([`checkov.yaml`](checkov.yaml); fails on **HIGH** and **CRITICAL**; **`--skip-download`** for offline use, no Prisma Cloud API key). Install both locally with `make security-check-bin` (or `make gitleaks` / `make checkov`). Checkov GitHub release zips have no upstream checksum file; when bumping **`CHECKOV_VERSION`**, add or update **`hack/checksums/checkov-<version>.sha256sums`** (one line per platform zip) and verify with `sha256sum -c` before committing.

## Commit format

This repository enforces commit subjects in this format:

`[JIRA-TICKET] | [TYPE][(scope)][!]: [short description]`

Examples:

- `OCM-12345 | feat: add day-1 setting support`
- `OCM-12345 | fix(cluster): validate machine pool defaults`
- `OCM-12345 | feat!: change upgrade behavior`
- `OCM-00000 | chore: adjust CI workflow`

Allowed `TYPE` values:

- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation-only changes
- `style`: Formatting and non-functional style changes
- `refactor`: Refactoring with no behavior change
- `test`: Add or correct tests
- `chore`: Build/task/maintenance work
- `build`: Build system or dependency updates
- `ci`: Continuous integration changes
- `perf`: Performance improvements

CI validates commit messages on pull requests targeting `main` with:

- `.github/workflows/check-commit-format.yml`
- `make commits/check`
- `hack/commit-msg-verify.sh`

## Release process and changelog automation

The changelog is generated with [git-cliff](https://git-cliff.org/) using `cliff.toml`.
Only the `CHANGELOG.md` in the `main` branch contains the full changelog history.

Workflow:

1. Push a stable release tag (for example, `v1.7.3`).
2. GitHub Actions validates the tag and finds the previous stable release tag.
3. The workflow generates changelog entries and opens a pull request to `main` with label `changelog`.

Manual changelog generation:

```bash
# Generate changelog for a specific release range
git-cliff v1.7.2..v1.7.3 --prepend CHANGELOG.md
```

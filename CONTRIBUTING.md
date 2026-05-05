# Contributing

Thanks for helping improve this module. Please open pull requests against **`main`**, and run through the short checklist below before you submit—whether you wrote the change yourself, paired with a tool, or used an AI assistant. It keeps reviews quick and consistent for everyone.

This repo is **ROSA HCP** only. The sibling **ROSA Classic** module is [`terraform-rhcs-rosa-classic`](https://github.com/terraform-redhat/terraform-rhcs-rosa-classic) — do not mix architectures, resources, or variable names between the two.

## AI assistants & Cursor

| Location | Purpose |
|----------|---------|
| [`.cursor/rules/`](.cursor/rules/) | Hard guardrails in `.mdc` files (always-on in Cursor): HCP vs Classic, provider/version constraints, variables, security baseline |
| [`AGENTS.md`](AGENTS.md) | Skills, workflow, security (agent checks), testing expectations; commands live in **`CONTRIBUTING.md`**; canonical guardrails in **`.cursor/rules/`** |
| [`CLAUDE.md`](CLAUDE.md), [`GEMINI.md`](GEMINI.md) | One-line pointers to [`AGENTS.md`](AGENTS.md) (names match Claude Code / Gemini CLI defaults) |

**HashiCorp Terraform skills** (optional reference when generating or refactoring HCL): [terraform skills in agent-skills](https://github.com/hashicorp/agent-skills/tree/main/terraform) — e.g. **terraform-style-guide**, **terraform-test**, **refactor-module**. If a skill conflicts with **`CONTRIBUTING.md`**, **`CONTRIBUTING.md`** takes precedence (see [`AGENTS.md`](AGENTS.md)).

## Before you open a PR

1. **Format** — `terraform fmt -recursive` (or format only dirs you changed).
2. **Validate** — `make verify` (runs `terraform init` + `validate` in each `examples/*` directory). Fix failures in examples you touch or that your change breaks.
3. **Docs** — If you changed variables, outputs, modules, or root wiring: run `make verify-gen` (runs `terraform-docs` via [`scripts/terraform-docs.sh`](scripts/terraform-docs.sh), then [`scripts/verify-gen.sh`](scripts/verify-gen.sh) to ensure README inject blocks are committed).
4. **Module tests** — If a submodule under `modules/<name>/tests/` has `*.tftest.hcl`, run `terraform init -backend=false && terraform test` from `modules/<name>/`.
5. **Provider** — Treat [`terraform-redhat/rhcs`](https://github.com/terraform-redhat/terraform-provider-rhcs) as the source of truth: mirror its schemas in variables and docs. Add `validation` / `precondition` only to echo the provider’s required fields and allowed values (fail fast); do not duplicate or tighten rules the provider already enforces.
6. **Module scope (AWS-only)** — If the change adds or expands **AWS-only** configuration (no `rhcs` surface), confirm it matches **Module scope (AWS-only vs core HCP)** in [`.cursor/rules/rosa-hcp-terraform.mdc`](.cursor/rules/rosa-hcp-terraform.mdc). In the PR, **link official Red Hat or cited ROSA HCP documentation** that supports shipping it in-repo, or explain why an exception is justified.

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

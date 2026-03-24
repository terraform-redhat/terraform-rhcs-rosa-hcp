# Contributing

We welcome PRs against `main`. Use the checklist below before you open a PR.

## Before you open a PR

1. **Format** — `terraform fmt -recursive` (or format only dirs you changed).
2. **Validate** — `make verify` (runs `terraform init` + `validate` in each `examples/*` directory). Fix failures in examples you touch or that your change breaks.
3. **Docs** — If you changed variables, outputs, modules, or root wiring: run `make verify-gen` (runs `terraform-docs` via [`scripts/terraform-docs.sh`](scripts/terraform-docs.sh), then [`scripts/verify-gen.sh`](scripts/verify-gen.sh) to ensure README inject blocks are committed).
4. **Module tests** — If a submodule under `modules/<name>/tests/` has `*.tftest.hcl`, run `terraform init -backend=false && terraform test` from `modules/<name>/`.
5. **Provider** — Treat [`terraform-redhat/rhcs`](https://github.com/terraform-redhat/terraform-provider-rhcs) as the source of truth: mirror its schemas in variables and docs. Add `validation` / `precondition` only to echo the provider’s required fields and allowed values (fail fast); do not duplicate or tighten rules the provider already enforces.

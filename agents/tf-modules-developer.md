# Terraform modules developer

Implement an approved change to this ROSA Terraform module.

## Workflow

1. Read the approved plan, then `AGENTS.md`, `CONTRIBUTING.md`, and every relevant `developer-docs/` file before editing.
2. Inspect established patterns in the affected module, its root wiring, examples, and tests. Keep changes narrow and preserve public variable and output contracts unless the plan includes a migration.
3. Implement with the repository's provider constraints, Terraform style, security requirements, and HCP-only architecture. For ROSA CLI interoperability, verify names and validation rules against the CLI source.
4. Update examples, tests, generated documentation inputs, and provider constraints whenever the interface or behavior requires them. Add both branches for boolean behavior and expected-failure coverage for new variable validation.
5. Run the applicable checks from `CONTRIBUTING.md`; report commands run, results, and any checks deliberately not run.

## Completion criteria

The change is internally consistent across module, examples, tests, and documentation; required checks pass or remaining failures are precisely reported with their cause.

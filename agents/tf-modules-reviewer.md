# Terraform modules reviewer

Review a proposed change to this ROSA Terraform module for correctness and maintainability.

## Workflow

1. Read `AGENTS.md`, `CONTRIBUTING.md`, and the `developer-docs/` material relevant to the changed paths before reviewing the diff.
2. Compare the change with existing module patterns, root wiring, examples, tests, provider constraints, and official provider or ROSA documentation when the diff relies on external behavior.
3. Check architectural scope, public-interface compatibility, provider floors, Terraform behavior, IAM least privilege, secret handling, sensitivity propagation, validation rules, test coverage, and generated-documentation impact.
4. Confirm HCP-only resources and semantics; identify any Classic-only pattern or unsupported provider attribute.
5. Report only actionable findings, ordered by severity, with file and line references, impact, and a concrete correction. State the residual risks and checks that could not be verified.

## Completion criteria

Every material regression or unmet repository guardrail is either reported with evidence or explicitly ruled out; the review distinguishes blocking findings from optional improvements.

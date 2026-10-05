# Terraform modules architect

Plan changes to this ROSA Terraform module before implementation.

## Workflow

1. Read the repository's `AGENTS.md`, `CONTRIBUTING.md`, and `developer-docs/architecture.md`.
2. Classify the request: root module, existing submodule, new AWS-only submodule, example, provider dependency, or documentation/test change. Read each conditionally relevant document named by `AGENTS.md` before proposing a solution.
3. Inspect the affected Terraform, examples, tests, provider constraints, and generated-documentation boundaries. Use the provider schema and official ROSA documentation when the change depends on a provider or platform capability.
4. Produce a smallest-safe plan that identifies affected files, public-interface impact, provider-version impact, HCP-specific constraints, test coverage, documentation generation, and validation commands.
5. Surface decisions requiring maintainer input rather than choosing an incompatible interface or unsupported architecture.

## Completion criteria

The plan names the supporting evidence, preserves the module's HCP architecture and compatibility commitments, and gives an implementer unambiguous acceptance criteria.

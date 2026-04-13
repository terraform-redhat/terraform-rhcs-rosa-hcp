# Terraform Style Conventions -- terraform-rhcs-rosa-hcp

## 1. Formatting and Linting

- All HCL must pass `terraform fmt -check -recursive`. Run `terraform fmt -recursive` before committing.
- tflint is configured via `.tflint.hcl` with the `tflint-ruleset-terraform` plugin (v0.14.1) and `call_module_type = "all"`. Run `make lint` which executes both `terraform fmt -check -recursive` and `tflint --recursive --disable-rule=terraform_required_providers`.
- `.tflintignore` excludes `.git`, `.terraform`, and lock files.

## 2. File Organization

Every module (root and submodules under `modules/`) follows this layout:

| File | Content |
|------|---------|
| `main.tf` | Resources, data sources, locals, module calls |
| `variables.tf` | All input variables |
| `outputs.tf` | All outputs (named `output.tf` in three child modules: route53-role, vpce-role, subnets-share) |
| `versions.tf` | `terraform` block with `required_version` and `required_providers` |

No `providers.tf` -- provider configurations live only in examples, never in reusable modules. Tests live in `modules/<name>/tests/*.tftest.hcl`. Examples live under `examples/<scenario-name>/` with the same four-file layout.

## 3. Naming Conventions

- **Variables, outputs, locals, resources:** `snake_case` exclusively. No camelCase or kebab-case.
- **Resource names:** Descriptive, purpose-based labels (`aws_iam_role.account_role`, `rhcs_cluster_rosa_hcp.rosa_hcp_cluster`, `rhcs_log_forwarder.this`). Use `this` only in single-resource modules.
- **Module call labels in root:** Match the service they wrap, prefixed with `rhcs_` for RHCS-backed modules (`module.rhcs_hcp_machine_pool`, `module.rhcs_identity_provider`) or a descriptive name for infrastructure modules (`module.account_iam_resources`, `module.oidc_config_and_provider`, `module.rosa_cluster_hcp`).
- **Module directory names:** Lowercase with hyphens (`machine-pool`, `oidc-config-and-provider`, `rosa-cluster-hcp`).
- **Variable naming prefixes:** Group related variables with a common prefix: `autoscaler_*`, `github_idp_*`, `openid_idp_*`, `aws_*`, `default_ingress_*`.

## 4. Variable Declaration Order and Structure

Within each `variable` block, use this attribute order:

```hcl
variable "example" {
  type        = string
  default     = null
  nullable    = false        # only when explicitly needed
  description = "Sentence describing the variable."
  sensitive   = true         # only when needed

  validation {
    condition     = ...
    error_message = "..."
  }
}
```

Key conventions observed:
- `type` always comes first, `description` always present.
- `default` comes after `type` when the variable is optional.
- Required variables omit `default`.
- `nullable` is set explicitly only when it must be `false` (e.g. `var.private`, `var.aws_subnet_ids`).
- `sensitive = true` is set on secrets (passwords, client secrets, user credential lists).

## 5. Variable Grouping with Section Comments

Related variables are grouped using hash-line section headers:

```hcl
##############################################################
# Proxy variables
##############################################################

variable "http_proxy" { ... }
variable "https_proxy" { ... }
```

This pattern uses a line of `#` characters (62 wide), a comment line with the section name, and a matching closing line. The same pattern appears in `main.tf` for grouping module calls and resource blocks.

Shorter separators (28 `#` characters) are used for subsections inside `main.tf`.

## 6. Comment Patterns

- **Section headers:** Hash-line banners as described above.
- **Inline HCL comments:** Use `#` for explanatory notes above or beside code. Use `//` sparingly (seen only for brief inline notes inside resource blocks, e.g., `// Billing ID can be empty for HCP GovCloud clusters`).
- **Comments in tests:** Placed above `run` blocks to describe what is being tested and why.
- Comments should explain *why*, not *what*. Do not restate what the code does.

## 7. Output Conventions

- Every output has `description` and `value`.
- `sensitive = true` must match submodule sensitivity -- if the child output is sensitive, the parent passthrough must also be `sensitive = true`.
- Conditional outputs use ternary: `value = var.create_x ? module.x[0].attr : null`.
- Outputs in `outputs.tf` are grouped by submodule using `##` comment headers.

## 8. Module Call Patterns

- `count` for optional modules gated by a boolean variable: `count = var.create_account_roles ? 1 : 0`.
- `for_each` for collection-based modules using typed map variables: `for_each = var.machine_pools`.
- `source` uses relative paths (`./modules/machine-pool`) in root; `../../` or `../../modules/` in examples.
- Arguments are aligned with `=` padding (terraform fmt handles this).
- Within a module call, arguments are grouped by subsection using inline `########` comments.

## 9. Validation and Preconditions

- **Variable `validation` blocks:** Used at the root module level to catch user errors early (enum checks, mutual exclusivity, non-empty lists).
- **`lifecycle` > `precondition`:** Used inside submodule resource blocks as a second defense line for cross-field rules that the provider also enforces.
- **Null-safety in `contains()`:** Never pass a possibly-null value directly to `contains()`. Use a short-circuiting ternary: `var.x == null ? true : contains(["a", "b"], var.x)`.
- **Import-safe `count`/`for_each`:** Drive `count`/`for_each` from `var.*`, never solely from resource attributes that can be null after `terraform import`.

## 10. Typed Maps vs map(any)

Prefer `map(object({ ... }))` with `optional(...)` for complex variable maps (like `machine_pools`, `log_forwarders`). Use `map(any)` only when the object schema is too polymorphic to type (like `identity_providers`). When using `map(object(...))`, add `validation` blocks for cross-field constraints.

## 11. versions.tf Conventions

- Root `versions.tf` sets the effective minimum for the entire module tree.
- Submodules declare their own `versions.tf` but their floors must not exceed the root's.
- Format: `>= X.Y.Z` for provider versions, `>= 1.6` at root (submodules may use `>= 1.0`).
- Provider attribute ordering: `source` before `version` is the predominant pattern across both `aws` and `rhcs` providers.

## 12. Documentation Generation

- `.terraform-docs.yml` at the repo root drives `terraform-docs` for all modules and examples.
- Docs inject into `README.md` between `<!-- BEGIN_AUTOMATED_TF_DOCS_BLOCK -->` and `<!-- END_AUTOMATED_TF_DOCS_BLOCK -->` markers.
- `scripts/terraform-docs.sh` runs `terraform-docs -c .terraform-docs.yml` for root, each `modules/*`, and each `examples/*`.
- After changing variables, outputs, or module wiring: run `make terraform-docs` then `make verify-gen` to confirm README blocks are up to date.
- Settings: sorted by name, `read-comments: true`, markdown table format, `mode: inject`.

## 13. Testing Conventions

- Test files: `modules/<name>/tests/<test_name>.tftest.hcl`.
- Use `mock_provider` blocks, not live credentials, for plan-mode unit tests.
- Test both success and failure paths. Use `expect_failures` for validation/precondition tests; use `assert` blocks for positive cases.
- When behavior branches on a boolean (`count = var.x ? 1 : 0`), test both `true` and `false` in separate `run` blocks.
- Name `run` blocks descriptively: `"valid_s3_and_applications_plan"`, `"both_s3_and_cloudwatch_fails"`.
- All tests run with `command = plan`.
- Run with `make unit-tests` (iterates `modules/*/tests/`).

## 14. Security Rules

- Never hardcode secrets, API keys, or long-lived AWS access keys.
- Mark sensitive variables and outputs with `sensitive = true`.
- Parent outputs passing through sensitive child outputs must also be `sensitive = true`.
- Follow STS/OIDC/IRSA patterns from existing `examples/`.

## 15. Conditional Resource Patterns

The repo uses a consistent ternary style for conditional expressions, especially for multi-line conditionals:

```hcl
value = condition ? (
  true_value
  ) : (
  false_value
)
```

The closing `)` and `) : (` are placed on their own lines when the expression spans multiple lines.

## 16. Locals Conventions

- `locals` block placed at the top of `main.tf`, before resources.
- Use `coalesce()` for defaulting nullable variables: `local.path = coalesce(var.path, "/")`.
- Use `locals` to compute derived values (ARN construction, prefix resolution) rather than repeating expressions inline.

## 17. Pre-PR Checklist (from CONTRIBUTING.md)

1. `terraform fmt -recursive`
2. `make verify` (init + validate all examples)
3. `make verify-gen` (terraform-docs + git-clean check)
4. `make unit-tests` (if touching submodules with tests)
5. Provider schemas are mirrored in variables and docs

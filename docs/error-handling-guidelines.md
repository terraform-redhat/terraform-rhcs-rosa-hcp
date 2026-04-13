# Error-Handling Guidelines

## Validation Philosophy

Validation in this repo exists to **fail fast** by echoing provider-required fields and allowed values. Do not duplicate or tighten rules the `rhcs` provider already enforces (per `CONTRIBUTING.md`). There are two layers: `validation` blocks on variables (checked at plan input time) and `lifecycle` preconditions on resources (checked at plan/apply time when runtime context is available).

## Variable Validation Blocks

### Null-safe short-circuiting (mandatory pattern)

Never pass a possibly-null value directly into `contains()` or similar functions. Use a ternary so the function only runs when the value is non-null:

```hcl
# CORRECT
condition = var.x == null ? true : contains(["a", "b"], var.x)

# WRONG -- produces "argument must not be null" when var.x is null
condition = var.x == null || contains(["a", "b"], var.x)
```

This pattern is used throughout (e.g. `aws_node_pool.capacity_reservation_preference`, `oidc_prefix`).

### Enum validation with `contains()`

For variables with a fixed set of allowed values, use `contains` with null-guard:

```hcl
validation {
  condition = var.aws_node_pool.capacity_reservation_preference == null ? true : contains(
    ["none", "open", "capacity-reservations-only"],
    var.aws_node_pool.capacity_reservation_preference
  )
  error_message = "capacity_reservation_preference must be one of: none, open, capacity-reservations-only."
}
```

### Regex validation (multi-block)

Split distinct constraints into separate `validation` blocks rather than combining them. Each block gets its own targeted error message:

```hcl
validation {
  condition     = var.oidc_prefix == null ? true : length(var.oidc_prefix) <= 16
  error_message = "The oidc_prefix must be maximum 16 characters"
}
validation {
  condition     = var.oidc_prefix == null ? true : can(regex("^[a-z][a-z0-9\\-]+[a-z0-9]$", var.oidc_prefix))
  error_message = "The oidc_prefix must start with a lowercase letter..."
}
```

### Map/list validation with `alltrue` + comprehensions

For validating entries in typed maps (`map(object({...}))`), iterate with `for` inside `alltrue`:

```hcl
validation {
  condition = alltrue([
    for _, lf in var.log_forwarders :
    (try(lf.s3, null) != null) != (try(lf.cloudwatch, null) != null)
  ])
  error_message = "Each log_forwarders entry must specify exactly one destination: either s3 or cloudwatch."
}
```

Use `coalesce(..., [])` to handle null lists inside comprehensions, and `trimspace()` to reject whitespace-only strings:

```hcl
condition = alltrue([
  for _, lf in var.log_forwarders :
  length([
    for app in coalesce(try(lf.applications, null), []) : app
    if trimspace(app) != ""
  ]) > 0
])
```

### Mutually exclusive field validation

For complex objects with mutually exclusive sub-fields, use nested null-checks:

```hcl
condition = var.registry_config == null ? true : (
  var.registry_config.registry_sources == null ? true : (
    !(
      length(coalesce(var.registry_config.registry_sources.allowed_registries, [])) > 0 &&
      length(coalesce(var.registry_config.registry_sources.blocked_registries, [])) > 0
    )
  )
)
```

### Non-empty list guard

When a list variable must not be empty (but null is acceptable), validate with `length`:

```hcl
condition     = var.aws_additional_control_plane_security_group_ids == null || length(var.aws_additional_control_plane_security_group_ids) > 0
error_message = "Security group list cannot be empty."
```

## Lifecycle Preconditions

### Where to use preconditions vs validation blocks

- **`validation` blocks**: For constraints on a single variable's value (type, format, enum, length).
- **`lifecycle` preconditions**: For cross-variable constraints and conditional requirements that depend on runtime context or multiple inputs together.

### Conditional-required-field pattern

The dominant precondition pattern is `(BAD_CONDITION) == false`. This double-negative style is used consistently throughout:

```hcl
lifecycle {
  precondition {
    condition     = (lower(var.idp_type) == "github" && var.github_idp_client_id == null) == false
    error_message = "\"github_idp_client_id\" mustn't be empty when creating Github Identity Provider."
  }
}
```

Follow this `(bad_thing) == false` pattern for new preconditions rather than inverting to `!(...)` -- it is the established convention.

### Cross-variable mutual exclusion

When two groups of variables are mutually exclusive or one implies the other:

```hcl
precondition {
  condition = (
    var.installer_role_arn != null && var.support_role_arn != null &&
    var.worker_role_arn != null && var.account_role_prefix != null
  ) == false
  error_message = "The \"account_role_prefix\" shouldn't be provided when all ARNs for account roles are specified."
}
```

### Feature-gate preconditions

When optional sub-features require an enabling flag:

```hcl
precondition {
  condition = (
    (var.autoscaler_max_pod_grace_period != null || ...)
    && var.cluster_autoscaler_enabled != true
  ) == false
  error_message = "Autoscaler parameters cannot be modified while the cluster autoscaler is disabled."
}
```

### Contextual error messages

Use conditional expressions in `error_message` when the same precondition can fail for opposite reasons:

```hcl
error_message = var.managed == true ? (
  "\"installer_role_arn\" variable should not contain a value when using a managed OIDC provider."
) : (
  "\"installer_role_arn\" variable should have a value when using an unmanaged OIDC provider."
)
```

### Standalone validation resource pattern

When preconditions are needed but no natural resource hosts them, use a `null_resource` named `validations` or `*_validation`:

```hcl
resource "null_resource" "validations" {
  lifecycle {
    precondition { ... }
  }
}
```

This is used in `main.tf` (root) and `modules/oidc-config-and-provider/main.tf` (named `unmanaged_vars_validation`).

## Lifecycle Rules

### `ignore_changes` for immutable fields

Use `ignore_changes` for fields that should not trigger updates after initial creation:

- `rhcs_hcp_machine_pool`: ignores `cluster` and `name` (identity fields)
- `vpc` resources: ignore `tags` (AWS may modify tags externally)

### `nullable = false` usage

Apply `nullable = false` on variables that must never be null and where a null would cause confusing downstream errors. Used on: `aws_subnet_ids`, `private`, `subnet_id`, `autoscaling`, `aws_node_pool`, `openshift_version`.

## Dual-layer validation (root + submodule)

For typed map variables consumed via `for_each`, apply validation at both layers:

1. **Root `variables.tf`**: `validation` blocks on the map variable catch user errors at plan input time (e.g. `log_forwarders` has 4 validation blocks).
2. **Submodule `main.tf`**: `lifecycle` preconditions on the resource re-check the same invariants as a safety net (e.g. `log-forwarder/main.tf` has 2 preconditions mirroring root validations).

This dual approach ensures errors surface early (root validation) and remain enforced if the submodule is used standalone.

## Error Message Conventions

- Quote variable names with escaped double quotes: `"\"variable_name\""`
- Use "mustn't be empty" for null-check failures on conditionally required fields
- Use "must be one of:" followed by a comma-separated list for enum failures
- Use "cannot" for mutual exclusion: "cannot specify both X and Y"
- State what is required, not just what failed
- Include the enabling condition context: "when creating Github Identity Provider", "while the cluster autoscaler is disabled"

## Test Patterns for Validation

### `expect_failures` for negative tests

Each validation/precondition should have a corresponding test run with `expect_failures`:

```hcl
run "invalid_capres_preference_fails" {
  command = plan
  variables { ... }
  # Point to the variable for validation failures
  expect_failures = [var.aws_node_pool]
}

run "github_missing_client_id_fails" {
  command = plan
  variables { ... }
  # Point to the resource for precondition failures
  expect_failures = [rhcs_identity_provider.github_identity_provider]
}
```

Key rule: `expect_failures` targets `var.<name>` for `validation` block failures and `resource_type.name` for `lifecycle` precondition failures.

### Both-branches coverage

When behavior branches on a boolean (e.g. `count = var.x ? 1 : 0`), test both outcomes in separate `run` blocks -- not just the default path. See `rosa_cluster_hcp.tftest.hcl` for `wait_for_create_complete` true/false.

### Edge cases to cover

Test whitespace-only strings, empty strings, empty lists, explicit nulls, and null-vs-omitted. The `log_forwarder.tftest.hcl` is the most thorough example of this approach.

### Mock providers

Use `mock_provider` blocks. Use `override_during = plan` with `mock_resource` defaults when computed values are needed during plan-only test runs.

# Terraform Module Design Guidelines -- terraform-rhcs-rosa-hcp

## Module Organization

The root module is a **facade** that composes submodules under `modules/`. It does not declare provider resources directly (except `rhcs_dns_domain` and a `null_resource` for cross-variable validation). All real work lives in submodules.

**Submodule categories:**
- **Core cluster:** `rosa-cluster-hcp` (always invoked, no `count`)
- **Optional infrastructure:** `account-iam-resources`, `oidc-config-and-provider`, `operator-roles` (gated by `count = var.create_* ? 1 : 0`)
- **Repeatable day-2 resources:** `machine-pool`, `idp`, `kubelet-configs`, `image-mirrors`, `log-forwarder` (iterated via `for_each` on a typed map variable)
- **Conditional singleton:** `additional-cp-sg` (gated by compound boolean `count`)
- **Nested composition:** `shared-vpc-resources` contains its own child modules (`route53-role`, `vpce-role`, `subnets-share`, `hosted-zones`)

**Rule:** Submodules should manage a single logical concern. Use nesting only when a parent submodule orchestrates tightly coupled AWS resources that share lifecycle timing (as `shared-vpc-resources` does).

## File Structure Per Module

Every module and submodule follows this layout:

| File | Content |
|------|---------|
| `main.tf` | Resources, data sources, locals |
| `variables.tf` | All input variables |
| `outputs.tf` | All outputs (named `output.tf` in three child modules: route53-role, vpce-role, subnets-share) |
| `versions.tf` | `terraform.required_version` and `required_providers` |

No other `.tf` files. Tests live in `modules/<name>/tests/*.tftest.hcl`. Examples live in `examples/`.

## Variable Design

**Attribute order in every `variable` block:**
```hcl
variable "example" {
  type        = <type>
  default     = <value>       # omit for required variables
  nullable    = false         # only when explicitly needed
  description = "..."
  sensitive   = true          # only for secrets
  validation { ... }          # optional
}
```

**Conventions:**
- Names use `snake_case`. Descriptions mirror upstream `rhcs` provider docs.
- Required variables omit `default`. Optional variables default to `null` (not `""`), except booleans which default to their safe value.
- Empty string `""` as default is used only when the empty value carries semantic meaning distinct from null (e.g. `default_ingress_listening_method`).
- `nullable = false` is set explicitly only on variables where null would break resource logic (e.g. `private`, `aws_subnet_ids`, `aws_node_pool`).
- Mark `sensitive = true` on any variable carrying secrets (`*_password`, `*_client_secret`, `*_bind_password`).

**Null-safe validation:** Never pass a possibly-null value into `contains()`. Use a ternary guard:
```hcl
condition = var.x == null ? true : contains(["a", "b"], var.x)
```

## Typed Map Variables for Repeatable Resources

Day-2 resources (machine pools, IDPs, log forwarders, kubelet configs, image mirrors) are exposed at the root as typed map variables consumed via `for_each`.

**Two patterns exist -- prefer the typed one for new work:**

1. **Typed `map(object({...}))` with `optional()`** (preferred, used by `machine_pools`, `log_forwarders`):
```hcl
variable "machine_pools" {
  type = map(object({
    name      = string
    subnet_id = string
    replicas  = optional(number)
    # ...
  }))
  default = {}
}
```

2. **Untyped `map(any)`** (legacy, used by `identity_providers`, `kubelet_configs`, `image_mirrors`):
```hcl
variable "identity_providers" {
  type    = map(any)
  default = {}
}
```
The `map(any)` pattern requires `try()` wrappers in root `main.tf` and `jsonencode`/`jsondecode` for complex fields. New variables should use the typed pattern to get compile-time type checking.

**Root `main.tf` wiring for `for_each` modules:**
```hcl
module "rhcs_hcp_machine_pool" {
  source   = "./modules/machine-pool"
  for_each = var.machine_pools

  cluster_id = module.rosa_cluster_hcp.cluster_id
  name       = each.value.name
  replicas   = try(each.value.replicas, null)  # try() for optional fields
}
```

**Add root-level `validation` blocks** for cross-field constraints users should hit early (e.g. mutually exclusive fields). Child modules add `lifecycle { precondition }` as defense-in-depth.

## count vs for_each

- **`count = var.create_x ? 1 : 0`** for optional singleton submodules gated by a boolean variable.
- **`for_each = var.typed_map`** for repeatable resources.
- **`count = length(list)`** for iterating over a fixed-size list of homogeneous items (e.g. `account_roles_properties`, `operator_roles_properties`).
- Prefer deriving `count`/`for_each` from `var.*` or stable `local.*` values computed from variables. Avoid driving them solely from resource attributes that may be null or unknown after `terraform import` before refresh.

## Output Design

- Every output has `description`. Match the submodule output's sensitivity in root passthrough.
- Conditional module outputs use ternary: `value = var.create_x ? module.x[0].output : null`.
- For `for_each` modules, aggregate into a map: `value = { for k, v in module.x : k => v.output_id }`.
- Mark `sensitive = true` on outputs derived from sensitive values (passwords, usernames tied to admin credentials).

## time_sleep for Propagation Delays

Submodules that create resources requiring eventual consistency delays (`account-iam-resources`, `operator-roles`, `oidc-config-and-provider`, `shared-vpc-resources` for IAM; `vpc`, `bastion-host` for other AWS resources) use `time_sleep` resources with `create_duration` and `triggers` to:
1. Enforce propagation delay before downstream consumers read the resources.
2. Route all outputs through `time_sleep.*.triggers["key"]` so Terraform's dependency graph ensures ordering.

**Always output through the `time_sleep` triggers, not directly from the resource.** This is a deliberate pattern, not accidental indirection.

## Lifecycle Blocks

- `ignore_changes` on immutable fields (e.g. `cluster`, `name` in machine pools) to prevent unnecessary replacements.
- `precondition` for runtime validation of cross-variable constraints that cannot be expressed in `validation` blocks (requires resource context).

## Validation Strategy

Three layers, from earliest to latest:
1. **Variable `validation`** -- catches invalid input before plan (enum values, format regex, mutual exclusion).
2. **`null_resource` with `precondition`** -- cross-variable checks in root module that need no resource context.
3. **Resource `lifecycle { precondition }`** -- checks inside submodules that reference resource attributes or need module-scoped context.

## Examples

- Each example is a standalone root module under `examples/rosa-hcp-*`.
- Examples reference the root module via `source = "../../"` or submodules via `source = "../../modules/<name>"`.
- Simple examples (public, private) use the root facade. Complex examples (shared-vpc) compose submodules directly for finer control.
- Examples declare `cluster_name` as a required variable and `openshift_version` as optional with defaults, hardcoding sensible defaults for other inputs.
- Most examples include a regex validation on `openshift_version`: `^[0-9]*[0-9]+.[0-9]*[0-9]+.[0-9]*[0-9]+$` (exception: rosa-hcp-private-shared-vpc omits this validation).
- Each example includes a VPC module call (`modules/vpc`) to be self-contained.

## Testing

- Tests live in `modules/<name>/tests/*.tftest.hcl`.
- Use `mock_provider` blocks to avoid live credentials. Define aliases for different mock configurations.
- Cover both positive (`assert`) and negative (`expect_failures`) cases.
- When behavior branches on a boolean or conditional, test both paths (e.g. valid and invalid enum values, null vs non-null optional fields).
- Tests use `command = plan` for validation checks and `command = apply` only when testing stateful lifecycle behavior (e.g. `ignore_changes`).

## Provider Constraints

- Root `versions.tf` declares minimum versions: `rhcs >= 1.7.3`, `aws >= 6.0`, `terraform >= 1.6`. These are the effective constraints for users of the root module.
- Submodules declare their own `versions.tf` with provider constraints that may differ from the root. Terraform merges all constraints, so the highest minimum version across the tree becomes effective.
- Submodules that need only AWS do not declare `rhcs`. Do not add `rhcs` to an AWS-only submodule unless the change truly requires it.
- When a submodule needs a newer provider version, consider whether the root `versions.tf` should also be updated to maintain consistency.

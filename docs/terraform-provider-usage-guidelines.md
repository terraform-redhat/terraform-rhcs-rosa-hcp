# Terraform Provider Usage Guidelines

## Providers and Version Constraints

This module uses four providers. The **root `versions.tf`** sets the effective floor for the entire module tree.

| Provider | Source | Root Floor | Purpose |
|----------|--------|-----------|---------|
| `rhcs` | `terraform-redhat/rhcs` | `>= 1.7.3` | ROSA HCP cluster, machine pools, IDPs, autoscaler, ingress, OIDC config, DNS, kubelet configs, image mirrors, log forwarders |
| `aws` | `hashicorp/aws` | `>= 6.0` | IAM roles/policies, VPC, subnets, S3, Secrets Manager, Route 53, VPC endpoints |
| `null` | `hashicorp/null` | `>= 3.0.0` | Validation-only resources (`null_resource` with `lifecycle.precondition`) |

Additional providers appear only in specific submodules:
- `hashicorp/time` (`>= 0.9`): VPC, operator-roles, account-iam-resources, oidc-config-and-provider, shared-vpc-resources, bastion-host
- `hashicorp/random` (`>= 2.0`): account-iam-resources

**Terraform core**: `>= 1.6` at root, `>= 1.0` in submodules.

## Version Constraint Hierarchy

- Root `versions.tf` constraints must be **equal to or higher** than every submodule's floor. Terraform merges constraints across the tree; a root floor lower than a submodule floor causes resolution failures.
- Submodules declare their own `versions.tf` with only the providers they actually use. Some submodules are AWS-only (no `rhcs`).
- When bumping a submodule floor, always check whether the root floor must also increase.
- Submodule floors are currently inconsistent (e.g., `aws >= 4.0` in some, `>= 5.38.0` in others, `>= 6.0` in oidc-config-and-provider and account-iam-resources). The root `>= 6.0` governs at plan time.

## Provider Configuration

- **No provider configuration blocks exist in modules or submodules.** Provider configuration is the caller's responsibility.
- **No provider aliases** in modules/submodules. Aliases only appear in examples (e.g., `rosa-hcp-private-shared-vpc` uses `aws.cluster-owner` and `aws.network-owner` for cross-account shared-VPC).
- Examples pass aliased providers to submodules via `providers = { aws = aws.cluster-owner }`.

## RHCS Resource Naming Conventions

RHCS resources use the `rhcs_` prefix. HCP-specific resources include `_hcp_` in the name. Key resources:

| Resource | Submodule | Key Pattern |
|----------|-----------|-------------|
| `rhcs_cluster_rosa_hcp` | `rosa-cluster-hcp` | Single instance, no count/for_each |
| `rhcs_hcp_machine_pool` | `machine-pool` | Single instance per module; root uses `for_each` on the module call |
| `rhcs_hcp_cluster_autoscaler` | `rosa-cluster-hcp` | `count = var.cluster_autoscaler_enabled ? 1 : 0` |
| `rhcs_hcp_default_ingress` | `rosa-cluster-hcp` | `count = var.wait_for_create_complete ? 1 : 0` |
| `rhcs_identity_provider` | `idp` | One resource per IDP type, each with `count = lower(var.idp_type) == "<type>" ? 1 : 0` |
| `rhcs_dns_domain` | root | `count` gated by `var.create_dns_domain_reservation` |
| `rhcs_rosa_oidc_config` | `oidc-config-and-provider` | Always created; managed vs unmanaged controlled by `var.managed` |
| `rhcs_kubeletconfig` | `kubelet-configs` | Single instance; root uses `for_each` |
| `rhcs_image_mirror` | `image-mirrors` | Single instance; root uses `for_each` |
| `rhcs_log_forwarder` | `log-forwarder` | Single instance; root uses `for_each` |

## RHCS Data Sources

| Data Source | Where Used | Purpose |
|-------------|-----------|---------|
| `rhcs_hcp_policies.all_policies` | `account-iam-resources` | Retrieves SRE support role ARN for trust policies |
| `rhcs_info.current` | `account-iam-resources` | Gets OCM AWS account ID for installer role trust |
| `rhcs_rosa_oidc_config_input` | `oidc-config-and-provider` | Generates unmanaged OIDC configuration inputs |

## Multiplicity Patterns: count vs for_each

- **Boolean gating** uses `count`: `count = var.create_account_roles ? 1 : 0`. Consumers reference with `[0]` index: `module.account_iam_resources[0].account_roles_arn`.
- **Collection iteration** uses `for_each` at the root module call level: `for_each = var.machine_pools`. Each submodule internally has a single resource (no for_each inside).
- The IDP submodule is unique: it has multiple `rhcs_identity_provider` resources (one per type), each gated by `count` on `var.idp_type`. Only one resource is created per module invocation.
- **Do not** drive `count`/`for_each` from resource/data source attributes that may be null after import; use `var.*` inputs only.

## time_sleep Propagation Pattern

AWS IAM resources require propagation delays. This repo uses `time_sleep` with `triggers` to:
1. Force an explicit dependency chain (all IAM resources must complete before downstream consumers).
2. Add 10-20 second delays for IAM eventual consistency.
3. **Route outputs through `time_sleep.triggers`** so consumers implicitly wait.

```hcl
# Pattern: outputs read from time_sleep triggers, not directly from resources
output "operator_role_prefix" {
  value = time_sleep.role_resources_propagation.triggers["operator_role_prefix"]
}
```

Every submodule that creates IAM roles (account-iam-resources, operator-roles, oidc-config-and-provider) and VPC resources follows this pattern. When adding new outputs from these modules, route them through the existing `time_sleep` resource's `triggers` map.

## null_resource for Cross-Variable Validation

`null_resource` with `lifecycle.precondition` is used for validations that span multiple variables where `variable.validation` blocks cannot cross-reference other variables. This appears at root level and in `oidc-config-and-provider`.

```hcl
resource "null_resource" "validations" {
  lifecycle {
    precondition {
      condition     = (var.create_operator_roles == true && var.create_oidc != true && var.oidc_endpoint_url == null) == false
      error_message = "\"oidc_endpoint_url\" mustn't be empty when oidc is pre-created."
    }
  }
}
```

Prefer `lifecycle.precondition` on the actual resource when the validation is specific to that resource.

## AWS Resource Patterns

- **`data "aws_partition" "current"`** is used throughout for partition-aware ARN construction (supports GovCloud).
- **`data "aws_caller_identity" "current"`** is conditionally created (`count`) when the account ID/ARN can be supplied via variable instead.
- **`data "aws_availability_zones" "available"`** always filters with `opt-in-status = opt-in-not-required` to exclude Local Zones.
- AWS VPC resources use `lifecycle { ignore_changes = [tags] }` universally because ROSA may modify tags after creation.
- IAM roles are tagged with `rosa_managed_policies = true`, `rosa_hcp_policies = true`, and `red-hat-managed = true`.

## Variable-to-Resource Schema Mapping

Root module variables mirror RHCS provider resource attributes but are often renamed or flattened:
- Nested provider objects become flat variables: `rhcs_cluster_rosa_hcp.proxy` block maps to four root variables (`http_proxy`, `https_proxy`, `no_proxy`, `additional_trust_bundle`); the submodule re-assembles the object.
- The `sts` object on `rhcs_cluster_rosa_hcp` is assembled in `locals` from individual role ARN variables.
- IDP configuration uses `jsondecode()` at the root level for list/map fields passed as JSON-encoded strings from `map(any)` typed `identity_providers` variable. Prefer `map(object({...}))` with `optional()` for new typed map variables.

## Sensitive Outputs

`cluster_admin_username` and `cluster_admin_password` are both `sensitive = true` in root and submodule outputs. Any new output derived from sensitive provider attributes must also set `sensitive = true` at both levels.

## Submodule Provider Boundaries

Some submodules are intentionally AWS-only. Do not add `rhcs` resources to:
- `vpc`, `bastion-host`, `additional-cp-sg`
- `shared-vpc-resources` and its children (`hosted-zones`, `route53-role`, `subnets-share`, `vpce-role`)

Only add `rhcs` to a submodule that already declares it, or create a new submodule if the feature requires both providers.

## lifecycle.ignore_changes

- `rhcs_hcp_machine_pool`: ignores `cluster` and `name` (immutable after creation).
- All AWS VPC-related resources: ignore `tags` (ROSA modifies tags externally).
- Do not add blanket `ignore_changes` without documenting why external modification is expected.

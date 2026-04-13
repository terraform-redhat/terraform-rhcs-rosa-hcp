# Integration Guidelines -- terraform-rhcs-rosa-hcp

## Module Architecture Overview

The root module orchestrates submodules via boolean `create_*` flags and `for_each` maps.
Resources are created conditionally with `count`; consumers must index into `[0]` when
referencing conditional module outputs. The orchestration order is:
`account-iam-resources` -> `oidc-config-and-provider` -> `operator-roles` -> `rosa-cluster-hcp` -> post-cluster resources (IDP, machine pools, log forwarders, etc.).

## Identity Provider (IDP) Integration

### Dispatch pattern

The `modules/idp` submodule uses a **single `idp_type` discriminator** variable with a validation
constraint: `["github", "gitlab", "google", "htpasswd", "ldap", "openid"]`. Each IDP type is a
**separate `rhcs_identity_provider` resource** gated by `count = lower(var.idp_type) == "<type>" ? 1 : 0`.
Never combine multiple IDP types in a single module invocation.

### Root module wiring -- `map(any)` with JSON-encoded complex fields

The root `identity_providers` variable is typed `map(any)` (not `map(object(...))`). Each map
entry represents one IDP. **List/map fields must be passed as JSON-encoded strings** at the root
level and decoded with `jsondecode()` in `main.tf`:

```hcl
# Root main.tf pattern for list fields:
github_idp_organizations = try(jsondecode(each.value.github_idp_organizations), null)
openid_idp_claims_email  = try(jsondecode(each.value.openid_idp_claims_email), null)
```

When adding a new IDP attribute, follow this chain:
1. Add the variable to `modules/idp/variables.tf` (with `sensitive = true` for secrets).
2. Wire it in `modules/idp/main.tf` inside the correct `rhcs_identity_provider.<type>` resource.
3. Add the passthrough in root `main.tf` under `module "rhcs_identity_provider"`, using
   `try(each.value.<field>, null)` for scalar fields or `try(jsondecode(each.value.<field>), null)`
   for list/map fields.
4. No root `variables.tf` change needed -- `map(any)` absorbs new keys.

### Required fields per IDP type

Each IDP resource has `lifecycle.precondition` blocks enforcing required fields. When adding
a new IDP type or field, add corresponding preconditions. The convention is:

```hcl
precondition {
  condition     = (lower(var.idp_type) == "<type>" && var.<field> == null) == false
  error_message = "\"<field>\" mustn't be empty when creating <Type> Identity Provider."
}
```

Note: Not all required fields have preconditions. For example, `openid_idp_issuer` is documented as required but lacks a precondition check, relying on provider-level validation.

### Sensitive fields

All `*_client_secret` and `*_bind_password` variables carry `sensitive = true` in the submodule.
The `htpasswd_idp_users` variable (containing passwords) is also sensitive. Keep this convention
when adding new credential fields.

## OIDC Configuration

### Managed vs unmanaged

The `oidc-config-and-provider` module branches on `var.managed` (default `true`):

- **Managed** (`managed = true`): Red Hat hosts the OIDC endpoint. Only creates `rhcs_rosa_oidc_config`
  and `aws_iam_openid_connect_provider`. No S3 bucket, no Secrets Manager.
- **Unmanaged** (`managed = false`): Customer-hosted. Creates S3 bucket with discovery doc and JWKS,
  Secrets Manager secret for the private key, and the OIDC config with `installer_role_arn` (required).

The `installer_role_arn` parameter is **required for unmanaged, must be null for managed** --
enforced by `null_resource.unmanaged_vars_validation`.

### Propagation timing

The module uses `time_sleep.wait_10_seconds` (10s create + 10s destroy) gated on all resource
triggers. Outputs (`oidc_config_id`, `oidc_endpoint_url`) flow through `time_sleep.triggers`
to enforce ordering. This pattern ensures IAM propagation before downstream use.

### Client ID list

The `aws_iam_openid_connect_provider` always registers two client IDs: `["openshift", "sts.amazonaws.com"]`.
Do not modify this list without understanding the STS trust chain.

## AWS Service Integration

### VPC module (`modules/vpc`)

Creates a complete VPC with public + private subnets, NAT gateways per AZ, internet gateway,
S3 VPC endpoint, and route tables. Key conventions:
- Subnet tags include `kubernetes.io/role/elb` (public) and `kubernetes.io/role/internal-elb` (private).
- Uses `time_sleep.vpc_resources_wait` (20s) to ensure all routes/associations are propagated.
- Filters availability zones with `opt-in-status = opt-in-not-required` to exclude Local Zones.

### IAM roles -- account and operator

**Account roles** (`account-iam-resources`): Three roles -- Installer, Support, Worker. Each uses
AWS managed ROSA policies (`ROSAInstallerPolicy`, `ROSASRESupportPolicy`, `ROSAWorkerInstancePolicy`). Trust policies reference Red Hat's OCM
AWS account (from `data.rhcs_info.current`).

**Operator roles** (`operator-roles`): Eight roles for OpenShift operators. Trust policies use
`sts:AssumeRoleWithWebIdentity` federated through the OIDC provider, with `StringEquals` condition
on the `sub` claim matching specific service accounts.

Both modules use `time_sleep` for IAM propagation and support shared VPC policy attachments.

### Role naming convention

```
Account:  {prefix}-HCP-ROSA-{Installer|Support|Worker}-Role  (truncated to 64 chars)
Operator: {prefix}-{namespace}-{operator_name}                (truncated to 64 chars)
```

### Tags convention for IAM

All ROSA-managed IAM resources carry these tags:
```hcl
tags = merge(var.tags, {
  red-hat-managed       = true
  rosa_hcp_policies     = true
  rosa_managed_policies = true
})
```
Shared VPC resources additionally get `hcp-shared-vpc = true`.

### Shared VPC pattern (cross-account)

The `rosa-hcp-private-shared-vpc` example demonstrates:
- Two AWS provider aliases: `aws.cluster-owner` and `aws.network-owner`.
- VPC created in network-owner account, shared via `shared-vpc-resources` module (RAM, Route53 roles, VPCE roles).
- Cluster created in cluster-owner account with `shared_vpc` block referencing hosted zone IDs and role ARNs.
- Cyclic dependency on shared VPC role ARNs is resolved by pre-computing ARN strings from naming conventions.

### Control plane security groups (`additional-cp-sg`)

Only available for private clusters on OpenShift >= 4.17.2. The root module validates this with
a version comparison precondition. Uses `data.aws_vpc_endpoint` filtered by tag `api.openshift.com/id`.

## Log Forwarding

### Destination exclusivity

Each log forwarder entry must specify **exactly one** of `s3` or `cloudwatch` -- enforced by both
root `variables.tf` validation and submodule `lifecycle.precondition`. Additionally, at least one
of `applications` or `groups` must be non-empty with non-whitespace values.

### Root variable typing

`log_forwarders` uses `map(object({...}))` with `optional()` (not `map(any)`). This provides compile-time type checking for mixed entries and is recommended when the object schema is well-defined.

### CloudWatch requires a role ARN

The `cloudwatch` destination requires `log_distribution_role_arn` -- an IAM role ARN that grants
the cluster permission to write to CloudWatch. This role is **not** created by the module; the
user must provision it externally.

### S3 destination

The `s3` destination requires `bucket_name` and optionally `bucket_prefix`. The S3 bucket itself
is **not** created by the module.

## Propagation and Timing

All modules that create AWS resources use `time_sleep` resources to handle eventual consistency:
- VPC: 20s create + 20s destroy
- Account IAM: 10s create + 10s destroy
- Operator roles: 20s create
- OIDC: 10s create + 10s destroy
- Shared VPC: 20s create + 20s destroy

Outputs are routed through `time_sleep.triggers` so downstream modules implicitly wait.
When adding new resources that affect IAM or networking, follow this pattern.

## Validation Patterns

The repo uses two layers of validation:
1. **`variable` validation blocks** in root `variables.tf` -- catch errors at plan time.
2. **`lifecycle.precondition`** in submodule resources -- catch errors closer to the resource.

For cross-field validations (e.g., "exactly one of A or B"), prefer root validation blocks.
For type-specific required-field checks, use submodule preconditions. The `null_resource.validations`
in root `main.tf` handles cross-module preconditions (e.g., OIDC + operator roles consistency).

## Examples -- Canonical Patterns

| Example | Demonstrates |
|---------|-------------|
| `rosa-hcp-public` | Minimal public cluster, htpasswd IDP via submodule direct call |
| `rosa-hcp-private` | Private cluster, bastion host, admin credentials |
| `rosa-hcp-public-unmanaged-oidc` | Unmanaged OIDC (`managed_oidc = false`), htpasswd via submodule |
| `rosa-hcp-public-with-multiple-machinepools-and-idps` | All 6 IDP types via root `identity_providers` map, multiple machine pools and kubelet configs |
| `rosa-hcp-public-with-sts-external-id` | STS external ID for trust policy |
| `rosa-hcp-private-shared-vpc` | Cross-account shared VPC with dual AWS providers |

When adding a new integration, create or update an example. Examples use `source = "../../"` for
the root module or `source = "../../modules/<name>"` for submodules.

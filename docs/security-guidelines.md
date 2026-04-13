# Security Guidelines -- terraform-rhcs-rosa-hcp

## 1. STS and IAM Role Architecture

This module exclusively uses AWS Security Token Service (STS) for ROSA HCP authentication. Three account roles and eight operator roles are created following Red Hat's prescribed structure.

**Account roles** (in `modules/account-iam-resources`):
- `HCP-ROSA-Installer` -- trusts Red Hat's managed OpenShift Installer role via `sts:AssumeRole`; optionally protected with `sts:ExternalId`
- `HCP-ROSA-Support` -- trusts Red Hat SRE support role; no external ID
- `HCP-ROSA-Worker` -- trusts the `ec2.amazonaws.com` service principal; no external ID

**Operator roles** (in `modules/operator-roles`): eight roles use `sts:AssumeRoleWithWebIdentity` with a `Federated` OIDC principal and `StringEquals` condition on `<oidc_endpoint>:sub` scoped to specific Kubernetes service accounts.

Rules for agents:
- Never add `sts:AssumeRole` to operator roles; they must use `sts:AssumeRoleWithWebIdentity` with OIDC federation.
- Never widen `condition` blocks on trust policies (e.g., changing `StringEquals` to `StringLike` or removing the `:sub` condition).
- Account and operator roles attach only AWS-managed `service-role/ROSA*` policies. Do not attach custom inline policies unless Red Hat documentation explicitly prescribes it.
- Always propagate `var.permissions_boundary` to `aws_iam_role` resources; never drop it.
- Role names are truncated to 64 characters with `substr(..., 0, 64)`. Maintain this pattern for any new role.

## 2. External ID for Trust Policies

The `trust_policy_external_id` variable adds a `StringEquals` condition on `sts:ExternalId` to the Installer role's trust policy only. This is conditionally applied via a `dynamic "condition"` block.

Rules:
- External ID applies only to the Installer account role. The Support and Worker roles have `external_id = null`. Do not change this mapping.
- The external ID must flow through: root variable -> `account-iam-resources` module -> cluster creation. Keep the chain intact.
- See `examples/rosa-hcp-public-with-sts-external-id` for the canonical usage pattern.

## 3. OIDC Configuration

Two modes exist, controlled by `var.managed` in `modules/oidc-config-and-provider`:

**Managed OIDC** (default): Red Hat hosts the OIDC provider. No S3 bucket, no Secrets Manager secret, no `installer_role_arn` required.

**Unmanaged OIDC**: Customer-hosted. Creates an S3 bucket (with public read for OIDC discovery documents), a Secrets Manager secret for the OIDC private key, and requires `installer_role_arn`.

Rules:
- The S3 bucket for unmanaged OIDC intentionally allows public `s3:GetObject` via bucket policy -- this is required for OIDC discovery. Do not add `block_public_policy = true` or `restrict_public_buckets = true` to the unmanaged path.
- The `block_public_acls` and `ignore_public_acls` settings are `true` even in unmanaged mode. Only bucket policy access is public, not ACLs.
- Private keys are stored in AWS Secrets Manager, never in Terraform outputs or local files.
- The `null_resource.unmanaged_vars_validation` precondition enforces mutual exclusivity: managed mode must not set `installer_role_arn`; unmanaged mode must set it. Preserve this validation.
- `client_id_list` on the OIDC provider is always `["openshift", "sts.amazonaws.com"]`. Do not modify this list.

## 4. Sensitive Value Handling

**Variables marked `sensitive = true`:**
- `admin_credentials_password` (root and `rosa-cluster-hcp` submodule)
- All IDP client secrets: `github_idp_client_secret`, `gitlab_idp_client_secret`, `google_idp_client_secret`, `openid_idp_client_secret`, `ldap_idp_bind_password`
- `htpasswd_idp_users` (contains passwords)

**Outputs marked `sensitive = true`:**
- `cluster_admin_username` and `cluster_admin_password` at both submodule and root level

Rules:
- If a submodule output has `sensitive = true`, any parent output passing it through must also have `sensitive = true`. Terraform enforces this at plan time.
- When adding new variables or outputs that carry credentials, tokens, private keys, or passwords, always set `sensitive = true`.
- Never log, echo, or include sensitive values in `properties`, `tags`, or `description` fields.
- Examples use `random_password` to generate admin passwords rather than hardcoded strings. Follow this pattern.

## 5. Security Group Patterns

**Bastion host** (`modules/bastion-host`): Creates a security group with SSH ingress restricted to the caller's public IP (`${chomp(data.http.myip.response_body)}/32`) plus optional `var.cidr_blocks`. Egress is open (`0.0.0.0/0` and `::/0`).

**Control plane additional SGs** (`modules/additional-cp-sg`): Attaches additional security groups to the PrivateLink VPC endpoint for the control plane. Gated by:
- `var.aws_additional_control_plane_security_group_ids != null`
- `var.private == true`
- OpenShift version >= 4.17.2 (validated via precondition in root `main.tf`)

**Compute additional SGs**: Passed via `aws_additional_compute_security_group_ids` directly to the `rhcs_cluster_rosa_hcp` resource.

Rules:
- Additional control plane SGs only apply to private clusters. The root `main.tf` enforces this with `count`. Do not remove the `private == false` guard.
- The version precondition on control plane SGs uses a numeric comparison pattern: `tonumber(format("%03d%03d%03d", split(".", var.openshift_version)...))`. Reuse this pattern for future version-gated features.
- Security group lists validate as non-empty when provided (`var.aws_additional_control_plane_security_group_ids == null || length(...) > 0`). Never allow an empty list to pass silently.

## 6. Shared VPC Cross-Account Trust

In shared VPC deployments, two cross-account IAM roles are created in the network-owner account:
- **Route53 role**: trusted by the cluster-owner's Installer, Ingress operator, and Control Plane operator roles
- **VPCE role**: trusted by the cluster-owner's Installer and Control Plane operator roles

Corresponding `assume_role_policy` documents are attached to the cluster-owner roles via `assets/assume_role_policy.tpl`, which grants only `sts:AssumeRole` on the specific shared VPC role ARN.

Rules:
- Shared VPC role names are deterministic (`${name_prefix}-shared-route53-role`, `${name_prefix}-shared-vpce-role`). The cluster-owner side pre-computes these ARNs to break the cyclic dependency. Do not change the naming convention without updating both sides.
- `permissions_boundary` is supported on shared VPC roles. Always propagate `var.permission_boundary` / `var.route53_permission_boundary` / `var.vpce_permission_boundary`.
- Shared VPC policy creation is controlled by `var.create_shared_vpc_policies` to avoid duplicates when policies are created in a separate step.

## 7. EC2 Instance Metadata Service (IMDS)

The `ec2_metadata_http_tokens` variable controls whether cluster nodes require IMDSv2. Values: `"optional"` (both v1 and v2, the default) or `"required"` (IMDSv2 only).

Rules:
- Most cluster examples set `ec2_metadata_http_tokens = "required"` as a security hardening measure. Follow this pattern in new examples unless there's a specific reason not to.
- Do not remove or weaken this setting in existing examples.

## 8. Encryption at Rest

Two KMS key ARN variables control encryption:
- `kms_key_arn`: encrypts cluster persistent storage (EBS volumes)
- `etcd_kms_key_arn`: encrypts etcd data on top of existing storage encryption (enabled via `etcd_encryption = true`)

Rules:
- These are optional (default `null`). Do not make them required.
- Both accept only full ARN format. Do not accept key IDs or aliases.

## 9. Credential Handling in Examples

Rules:
- Examples must never hardcode AWS access keys. Use `aws_profile` or `shared_credentials_files` variables.
- The shared VPC example accepts `access_key`/`secret_key` as variables (with `sensitive = true`). These are passed to aliased providers, never stored in state beyond the provider config.
- Admin passwords in examples always use `random_password` with complexity requirements (`min_lower`, `min_upper`, `min_numeric`, `min_special`, length >= 14).

## 10. Validation Patterns for Security Inputs

The repo uses two tiers of validation:
1. **`variable` validation blocks** -- for early input checks (null/empty/enum/format)
2. **`lifecycle` precondition blocks** -- for cross-variable or resource-dependent constraints

Key pattern for null-safe validation (from `.cursor/rules/rosa-hcp-terraform.mdc`):
```hcl
# Correct: short-circuit before calling contains() on a possibly-null value
condition = var.x == null ? true : contains(["a", "b"], var.x)

# Wrong: will error with "argument must not be null"
condition = var.x == null || contains(["a", "b"], var.x)
```

Rules:
- IDP modules use preconditions to enforce that required fields are non-null for the selected IDP type. Follow this `(lower(var.idp_type) == "X" && var.field == null) == false` pattern.
- Mutually exclusive options (e.g., `allowed_registries` vs `blocked_registries`, `s3` vs `cloudwatch` in log forwarders) must have explicit validation. Never allow both to be set simultaneously.

## 11. IAM Propagation Delays

All IAM-creating modules use `time_sleep` resources (10-20 seconds on both create and destroy) to handle AWS eventual consistency. Outputs are read from `time_sleep.triggers` to enforce ordering.

Rules:
- Never remove `time_sleep` resources from IAM modules. They prevent race conditions during cluster creation.
- New IAM resources must be added to the relevant `time_sleep.triggers` map so downstream consumers wait for propagation.

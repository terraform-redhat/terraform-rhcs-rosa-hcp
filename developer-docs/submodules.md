# Submodules

## AWS-only expansion

WHEN adding or expanding AWS-only configuration — all **In scope** criteria below must hold.
DEFAULT: Do not expand the module — use **examples** or user-owned Terraform.

## In scope (AWS-only) — all must hold

- MUST: Reference-aligned — standard ROSA HCP pattern in official Red Hat (or cited HCP-specific AWS) docs.
- MUST: High misconfiguration risk if users DIY.
- MUST: Testable and supportable (`terraform test`, examples, docs) without unbounded optional surface.

## Out of scope

- MUST NOT: Expand for optional AWS shapes that vary by customer, lack reference architecture, or lack official HCP docs.

## Implementation

WHEN an AWS-only pattern is **in scope** — implement in a first-party submodule with direct **`aws_*` resources**.
DEFAULT: Do not wrap third-party Terraform modules (community VPC/IAM wrappers).
- MUST NOT: Classic-only patterns in AWS-only submodules — they are still HCP modules.
- MUST NOT: Add `rhcs` to an intentionally AWS-only submodule unless truly required — follow that submodule's existing `main.tf` / `versions.tf`.
- MUST: AWS resources supported by root and submodule `versions.tf` floors — see [`providers-and-versions.md`](providers-and-versions.md).
- MUST: Submodule interface changes update root, **`examples/`**, and **`modules/*/tests/*.tftest.hcl`**.
- MUST: Least privilege for IAM/STS/OIDC/IRSA — link non-obvious cross-account or shared-VPC patterns to official ROSA HCP docs.
- MUST: `depends_on` / waits / preconditions when assuming immediate IAM/STS effect — follow the `time_sleep` pattern used by existing modules in this repo (see `modules/account-iam-resources` or `modules/operator-roles`).

WHEN a module encapsulates a resource whose Create fails if the resource already exists (i.e. non-idempotent, such as `rhcs_rosa_ocm_role_link`):
- MUST: Expose a boolean variable named `create_<resource>` (e.g. `create_link`), default `true`, with `count = var.create_<resource> ? 1 : 0` on that resource.
- MUST: Document the import path in the variable's `description` — users importing an existing resource set this to `false` to suppress the duplicate-create error on first apply.

## Cross-module IAM variable contract

WHEN adding or changing Variables shared across IAM submodules (`account-iam-resources`, `operator-roles`, `ocm-role`):
- MUST have a matching validation block for every format or value constraint — existing modules that omit it have a gap; do not copy the gap.

## AWS resource patterns

- `aws_iam_role` with a computed `name` or `path` MUST set `force_detach_policies = true` — if the name changes, Terraform recreates the role and may attempt deletion before detaching its policies.

## Module-specific

WHEN adding a new submodule — MUST add an entry to this section describing its
key constraints (tag contract, naming convention, policy source, required outputs).

- **modules/external-auth-provider:** MUST match the `rhcs_external_auth_provider` schema (`rhcs >= 1.7.13`). The cluster must be a ready ROSA HCP cluster created with `external_auth_providers_enabled = true`; that attribute is immutable after creation, so this submodule never sets it. OCM permits one provider per cluster. `console_client_secret` MUST be `sensitive = true`; `issuer_ca` is PEM content (not a path) and is **not** sensitive at 1.7.13 — do not diverge from the provider schema. Create is non-idempotent (HTTP 409), so `create_external_auth_provider` gates `count`; import id is `<cluster_id>,<name>` and requires the flag to stay `true`. Required output: `id` only.
- **modules/rosa-cluster-hcp:** MUST match provider for `rhcs_cluster_rosa_hcp`; document min OpenShift version when gated.
- **modules/shared-vpc-resources:** MUST follow shared VPC docs; narrow IAM bindings over broad IAM.
- **modules/ocm-role:** MUST match ROSA CLI tag contract (`red-hat-managed`, `rosa_role_type=OCM`, `rosa_role_prefix`, `rosa_admin_role` when admin). Trust and permission policy documents come from `data.rhcs_hcp_policies.ocm_role_policies` — do not hard-code ARNs or JSON. Role name follows `{prefix}-OCM-Role-{ocm_org_external_id}` (truncated to 64 chars, sourced from `data.rhcs_info.organization_external_id`). Output `role_arn` is the only input `rhcs_rosa_ocm_role_link` needs.

## Pull requests
- MUST: Link official docs on **primarily AWS-only** PRs.
- MUST pass items described in [`CONTRIBUTING.md`](../CONTRIBUTING.md) in Before you open a PR

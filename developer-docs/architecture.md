# Architecture

- MUST: **ROSA HCP only** — not [ROSA Classic](https://github.com/terraform-redhat/terraform-rhcs-rosa-classic).
- MUST NOT: Classic-only resources (e.g. `rhcs_cluster_rosa_classic`, non-HCP machine pools).
- MUST: Follow **this** repo's `main.tf` and `versions.tf` in shared submodules (e.g. `modules/idp`).
- MUST: Use [`terraform-redhat/rhcs`](https://github.com/terraform-redhat/terraform-provider-rhcs) registry schema/docs — do not invent attributes.

**See:** [AWS — ROSA architecture models](https://docs.aws.amazon.com/rosa/latest/userguide/rosa-architecture-models.html#rosa-architecture-differences)

## ROSA CLI parity (when applicable)

WHEN Terraform replaces or must interoperate with [ROSA CLI](https://docs.openshift.com/rosa/cli_reference/rosa_cli/rosa-get-started-cli.html) workflows:
- MUST: Match CLI naming and validation so ROSA tooling recognizes resources.
- PREFER: `rhcs_hcp_policies` for trust/permission documents (policy records, trust policies).
- PREFER: `rhcs_info` for organization metadata (e.g. `organization_external_id`).
- MUST: Put CLI-mirrored checks in `validation` blocks — see [`variables.md`](variables.md).
DEFAULT: If not interoperating with the ROSA CLI, prioritize pure **rhcs** provider defaults.

**See:** [`modules/ocm-role/`](../modules/ocm-role/)

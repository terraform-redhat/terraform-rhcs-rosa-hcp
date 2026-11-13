# external-auth-provider

## Introduction

This Terraform sub-module manages the [`rhcs_external_auth_provider`](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/external_auth_provider) resource for a ROSA HCP cluster. It registers an external OIDC token issuer so that the cluster authenticates users against that issuer instead of using the built-in OpenShift OAuth stack.

Prerequisites, each checked by the OpenShift Cluster Manager API before the provider is created, and each failing the create if it does not hold:

- The cluster must be a ROSA Hosted Control Plane cluster.
- The cluster must be in a `ready` state.
- The cluster must have been created with external authentication enabled.

Notes:

- OpenShift Cluster Manager permits one external authentication provider per cluster. A second create is rejected as a conflict rather than refused up front.
- A newly created provider can take a few minutes to become effective. Nothing in this sub-module waits for that.

> **Warning:** External authentication can only be enabled when the cluster is created. On the `rhcs_cluster_rosa_hcp` resource the attribute is `external_auth_providers_enabled`, and it cannot be changed after creation. This sub-module never sets that attribute and cannot turn external authentication on for an existing cluster. Run this sub-module only against a cluster that already has it enabled.

The `issuer_ca` input takes PEM certificate **content**, for example `file("ca.pem")`, not a file path.

The API never returns `console_client_secret`. An import therefore leaves it `null` in state, and the value must be present in the configuration before you update a confidential console client.

## Tests

From this directory (`modules/external-auth-provider`), run:

```bash
terraform init -backend=false
terraform test
```

[`tests/external_auth_provider.tftest.hcl`](./tests/external_auth_provider.tftest.hcl) uses a mocked `rhcs` provider and covers both `create_external_auth_provider` branches, every input validation, and the optional attributes that default to `null`.

## Example Usage

> **Note:** The Registry form `source = "terraform-redhat/rosa-hcp/rhcs//modules/external-auth-provider"`
> resolves only against a module release that contains the `modules/external-auth-provider` directory.
> Selected against a release that does not contain it, `terraform init` fails with
> `Unreadable module subdirectory`. Either select a release that includes this sub-module, or point
> `source` at a local path into a checkout of this repository, as below.

```
variable "console_client_secret" {
  type      = string
  sensitive = true
}

module "external_auth_provider" {
  # Local path to this sub-module inside a checkout of this repository. The path
  # shown here is what a configuration under examples/<name>/ uses; adjust it to
  # your own layout.
  source = "../../modules/external-auth-provider"

  cluster_id       = module.hcp.cluster_id
  name             = "example-provider"
  issuer_url       = "https://issuer.example.com/realms/rosa"
  issuer_audiences = ["console-client-id"]

  # Optional: PEM certificate content when the issuer uses a private CA.
  # issuer_ca = file("ca.pem")

  claim_mapping_username_claim = "email"
  claim_mapping_groups_claim   = "groups"

  console_client_id     = "console-client-id"
  console_client_secret = var.console_client_secret
}
```

## Import

Creating a provider that already exists fails, because the API returns a conflict and tells you to import it instead. There are two supported ways to deal with an existing provider, and they are not interchangeable.

**Take over management of an existing provider.** Keep `create_external_auth_provider = true` (the default) so the resource exists in the configuration at index `[0]`, write the module block to match the existing provider, then import it:

```bash
terraform import 'module.external_auth_provider.rhcs_external_auth_provider.this[0]' <cluster_id>,<name>
```

The address above is for a direct consumer of this sub-module. Through the root module the module block itself carries a `count`, so the address gains an index:

```bash
terraform import 'module.rhcs_hcp_external_auth_provider[0].rhcs_external_auth_provider.this[0]' <cluster_id>,<name>
```

Both addresses are relative to the root configuration that declares the module block. If you call the module from inside another module, prepend that module call path, for example `module.hcp.module.rhcs_hcp_external_auth_provider[0].rhcs_external_auth_provider.this[0]`. Quote the address in every case: `[0]` is a shell glob.

Run `terraform plan` afterwards and reconcile any drift. Because the provider is now in state, the next apply updates it instead of creating it. The console client secret is not returned by the API, so set `console_client_secret` in the configuration before you update a confidential console client.

**Leave an existing provider unmanaged.** Set `create_external_auth_provider = false`. Terraform then creates nothing and the conflict cannot occur. The root module does not expose this flag, so a root-module consumer with a pre-existing provider must use the import path above.

> **Warning:** With `create_external_auth_provider = false` the resource has `count = 0`, so the address `rhcs_external_auth_provider.this[0]` does not exist and cannot be used as an import target. Import first, and only then change the flag if you really want Terraform to stop managing the provider — note that flipping the flag to `false` while the provider is already in state plans its **destruction**.

<!-- BEGIN_AUTOMATED_TF_DOCS_BLOCK -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_rhcs"></a> [rhcs](#requirement\_rhcs) | >= 1.7.13 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_rhcs"></a> [rhcs](#provider\_rhcs) | >= 1.7.13 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [rhcs_external_auth_provider.this](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/external_auth_provider) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_claim_mapping_groups_claim"></a> [claim\_mapping\_groups\_claim](#input\_claim\_mapping\_groups\_claim) | ID token claim used to map groups. Set an empty string to clear the value. When null (default), the current API value is recorded in state. | `string` | `null` | no |
| <a name="input_claim_mapping_username_claim"></a> [claim\_mapping\_username\_claim](#input\_claim\_mapping\_username\_claim) | ID token claim used to construct usernames. Set an empty string to clear the value. When null (default), the current API value is recorded in state. | `string` | `null` | no |
| <a name="input_claim_validation_rule"></a> [claim\_validation\_rule](#input\_claim\_validation\_rule) | Rules for token claims in claim:required\_value format. The first colon separates the claim from the required value; later colons belong to the required value. Set an empty list to clear the rules. When null (default), the current API value is recorded in state. | `list(string)` | `null` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | Identifier of the ROSA HCP cluster. The cluster must be in a ready state and must have been created with external authentication enabled. | `string` | n/a | yes |
| <a name="input_console_client_id"></a> [console\_client\_id](#input\_console\_client\_id) | OIDC client ID used by the OpenShift console. Must be set together with console\_client\_secret and must appear in issuer\_audiences. Set both console client fields to empty strings to remove the console client. When null (default), the current API value is recorded in state. | `string` | `null` | no |
| <a name="input_console_client_secret"></a> [console\_client\_secret](#input\_console\_client\_secret) | OIDC client secret for the OpenShift console. Must be set together with console\_client\_id. The API never returns this value, so an import leaves it null in state and it must be present in the configuration before updating a confidential console client. Set both console client fields to empty strings to remove the console client. | `string` | `null` | no |
| <a name="input_console_extra_scopes"></a> [console\_extra\_scopes](#input\_console\_extra\_scopes) | Additional scopes requested by the OpenShift console client. Requires console\_client\_id and console\_client\_secret. Set an empty set to clear the scopes. When null (default), the current API value is recorded in state. | `set(string)` | `null` | no |
| <a name="input_create_external_auth_provider"></a> [create\_external\_auth\_provider](#input\_create\_external\_auth\_provider) | Create the external authentication provider. Creating a provider that already exists fails, because the API returns a conflict. To let Terraform adopt an existing provider, keep this true and run terraform import '<module address>.rhcs\_external\_auth\_provider.this[0]' <cluster\_id>,<name> (quote the address: [0] is a shell glob). To leave an existing provider unmanaged, set this to false; Terraform then creates nothing. Setting this to false for a provider that is already in state destroys that provider. (default: true) | `bool` | `true` | no |
| <a name="input_issuer_audiences"></a> [issuer\_audiences](#input\_issuer\_audiences) | Audiences for which tokens from the issuer are valid. Supply between one and ten values. When console\_client\_id is set, it must also appear in this set. | `set(string)` | n/a | yes |
| <a name="input_issuer_ca"></a> [issuer\_ca](#input\_issuer\_ca) | PEM-encoded CA certificate bundle content for the issuer, for example file("ca.pem"). This is certificate content, not a file path. Set an empty string to clear the value. When null (default), the current API value is recorded in state. | `string` | `null` | no |
| <a name="input_issuer_url"></a> [issuer\_url](#input\_issuer\_url) | HTTPS URL of the OIDC token issuer. Must be an absolute HTTPS URL with a host and without user information. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the external authentication provider. OCM uses this name as the identifier of the provider. Changing this value replaces the provider. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output\_id) | Identifier of the external authentication provider, which is its OCM name, or null when create\_external\_auth\_provider is false. |
<!-- END_AUTOMATED_TF_DOCS_BLOCK -->

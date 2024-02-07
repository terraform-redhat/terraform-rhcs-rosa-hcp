## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_rhcs"></a> [rhcs](#requirement\_rhcs) | >= 1.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_rhcs"></a> [rhcs](#provider\_rhcs) | >= 1.4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [rhcs_identity_provider.identity_provider](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/identity_provider) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | Identifier of the cluster. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the machine pool. Must consist of lower-case alphanumeric characters or '-', start and end with an alphanumeric character. | `string` | n/a | yes |
| <a name="input_github"></a> [github](#input\_github) | Details of the Github identity provider. | `map` | n/a | yes |
| <a name="input_gitlab"></a> [gitlab](#input\_gitlab) |Details of the Gitlab identity provider. | `map` | n/a | yes |
| <a name="input_google"></a> [google](#input\_google) | Details of the Google identity provider. | `map` | n/a | yes |
| <a name="input_htpasswd"></a> [htpasswd](#input\_htpasswd) | Details of the httpasswd identity provider. | `map` | n/a | yes |
| <a name="input_ldap"></a> [ldap](#input\_ldap) | Details of the LDAP identity provider | `map` | n/a | yes |
| <a name="input_openid"></a> [openid](#input\_openid) | Details of the OpenID identity provider | `map` | n/a | yes |
| <a name="input_mapping_method"></a> [mapping\_method](#input\_mapping\_method) | Specifies how new identities are mapped to users when they log in. Options are add, claim, generate and lookup. (default is claim) | `map` | n/a | yes |

## Outputs

No outputs.

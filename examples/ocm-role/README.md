# ocm-role example

Creates and links an OCM IAM role with the required ROSA CLI-parity tags using the `ocm-role` module.

<!-- BEGIN_AUTOMATED_TF_DOCS_BLOCK -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |
| <a name="requirement_rhcs"></a> [rhcs](#requirement\_rhcs) | >= 1.7.7 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_ocm_role"></a> [ocm\_role](#module\_ocm\_role) | ../../modules/ocm-role | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_ocm_role_prefix"></a> [ocm\_role\_prefix](#input\_ocm\_role\_prefix) | User-defined prefix for the OCM IAM role name. | `string` | `"ManagedOpenShift"` | no |
| <a name="input_profile"></a> [profile](#input\_profile) | Profile of the OCM role to create. Allowed values are `standard`, `admin`, and `no-console`. | `string` | `"standard"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | The ARN of the created OCM IAM role. |
| <a name="output_role_link_id"></a> [role\_link\_id](#output\_role\_link\_id) | The identifier of the OCM-side role link. |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | The name of the created OCM IAM role. |
<!-- END_AUTOMATED_TF_DOCS_BLOCK -->

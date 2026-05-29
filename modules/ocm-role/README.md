# ocm-role

## Introduction

This Terraform sub-module creates the AWS IAM OCM role with the tags required by the ROSA CLI and OCM. The role is used to grant OpenShift Cluster Manager permissions in the customer's AWS account.

The module creates the IAM role, attaches the appropriate permission policies for the selected profile, applies the required tags, and links the role to the current OCM organization via `rhcs_rosa_ocm_role_link`.

For more information, see [Understanding OCM role and User role for ROSA](https://access.redhat.com/articles/6961686).

## Example Usage

```
module "ocm_role" {
  source  = "terraform-redhat/rosa-hcp/rhcs//modules/ocm-role"
  version = "1.7.7"

  ocm_role_prefix = "ManagedOpenShift"
  profile         = "standard"
}
```

<!-- BEGIN_AUTOMATED_TF_DOCS_BLOCK -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |
| <a name="requirement_rhcs"></a> [rhcs](#requirement\_rhcs) | >= 1.7.7 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |
| <a name="provider_rhcs"></a> [rhcs](#provider\_rhcs) | >= 1.7.7 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_policy.ocm_admin_permission_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ocm_no_console_permission_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.standard_permission_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ocm_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ocm_admin_permission_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ocm_no_console_permission_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.standard_permission_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [rhcs_rosa_ocm_role_link.this](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/rosa_ocm_role_link) | resource |
| [rhcs_hcp_policies.all_policies](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/data-sources/hcp_policies) | data source |
| [rhcs_info.current](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/data-sources/info) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_create_link"></a> [create\_link](#input\_create\_link) | (Optional) Whether to link the created role to the OCM organization via rhcs\_rosa\_ocm\_role\_link. Set to false when importing an already-linked role. | `bool` | `true` | no |
| <a name="input_ocm_role_prefix"></a> [ocm\_role\_prefix](#input\_ocm\_role\_prefix) | User-defined prefix for the OCM IAM role name. The final role name is `<prefix>-OCM-Role-<organization_external_id>`. | `string` | n/a | yes |
| <a name="input_path"></a> [path](#input\_path) | (Optional) The IAM path for the OCM role and its policies. Must begin and end with '/'. | `string` | `"/"` | no |
| <a name="input_permissions_boundary"></a> [permissions\_boundary](#input\_permissions\_boundary) | (Optional) The ARN of the policy used to set the permissions boundary for the OCM IAM role. | `string` | `""` | no |
| <a name="input_profile"></a> [profile](#input\_profile) | Profile of the OCM role to create. Allowed values are `standard`, `admin`, and `no-console`. | `string` | `"standard"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Additional AWS resource tags to merge into the OCM role and its policies. | `map(string)` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | The ARN of the created OCM IAM role. |
| <a name="output_role_link_id"></a> [role\_link\_id](#output\_role\_link\_id) | The identifier of the OCM-side role link created for the IAM role, or null when create\_link is false. |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | The name of the created OCM IAM role. |
<!-- END_AUTOMATED_TF_DOCS_BLOCK -->

# account-iam-resources

Manage account-wide IAM roles and the policies attached to those roles.
Those roles are used for creating the resources in AWS, required for the Rosa cluster.

Those IAM resources can be created one time and used for multiple Rosa clusters creation.

## Prerequisites

To use this you will need:

* The [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) (1.2.0+) installed.
* The [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) installed.
* [AWS account](https://aws.amazon.com/free/?all-free-tier) and [associated credentials](https://docs.aws.amazon.com/IAM/latest/UserGuide/security-creds.html) that allow you to create resources. The credentials configured for the AWS provider (see [Authentication and Configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration) section in AWS terraform provider documentations)
* The [ROSA CLI](https://docs.openshift.com/rosa/rosa_cli/rosa-get-started-cli.html) installed
* [OpenShift Cluster Manager API Token](https://console.redhat.com/openshift/token)

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_rhcs"></a> [rhcs](#requirement\_rhcs) | >= 1.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_rhcs"></a> [rhcs](#provider\_rhcs) | >= 1.1.0 |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_account_iam_policy"></a> [account\_iam\_policy](#module\_account\_iam\_policy) | terraform-aws-modules/iam/aws//modules/iam-policy | n/a |
| <a name="module_account_iam_role"></a> [account\_iam\_role](#module\_account\_iam\_role) | terraform-aws-modules/iam/aws//modules/iam-assumable-role | n/a |

## Resources

| Name | Type |
|------|------|
| [null_resource.validate_openshift_version](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_string.default_random](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [time_sleep.wait_10_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_iam_policy_document.custom_trust_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| rhcs_policies.all_policies | data source |
| rhcs_versions.all_versions | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_role_prefix"></a> [account\_role\_prefix](#input\_account\_role\_prefix) | n/a | `string` | `null` | no |
| <a name="input_ocm_environment"></a> [ocm\_environment](#input\_ocm\_environment) | n/a | `string` | `"production"` | no |
| <a name="input_openshift_version"></a> [openshift\_version](#input\_openshift\_version) | The Openshift cluster version of the cluster those account roles are used for. Only major and minor parts (for example 4.1) | `string` | `"4.13"` | no |
| <a name="input_path"></a> [path](#input\_path) | (Optional) The arn path for the account/operator roles as well as their policies. | `string` | `"/"` | no |
| <a name="input_permissions_boundary"></a> [permissions\_boundary](#input\_permissions\_boundary) | The ARN of the policy that is used to set the permissions boundary for the IAM roles in STS clusters. | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | List of AWS resource tags to apply. | `map(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_role_prefix"></a> [account\_role\_prefix](#output\_account\_role\_prefix) | n/a |
| <a name="output_account_roles_arn"></a> [account\_roles\_arn](#output\_account\_roles\_arn) | n/a |
| <a name="output_openshift_version"></a> [openshift\_version](#output\_openshift\_version) | n/a |
| <a name="output_path"></a> [path](#output\_path) | n/a |

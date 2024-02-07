# oidc-provider

TODO

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
| <a name="provider_rhcs"></a> [rhcs](#provider\_rhcs) | >= 1.1.0 |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_openid_connect_provider.oidc_provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [rhcs_rosa_oidc_config.oidc_config](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/rosa_oidc_config) | resource |
| [time_sleep.wait_10_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | The cluster ID | `string` | `""` | no |
| <a name="input_installer_role_arn"></a> [installer\_role\_arn](#input\_installer\_role\_arn) | STS Role ARN with get secrets permission | `string` | n/a | yes |
| <a name="input_issuer_url"></a> [issuer\_url](#input\_issuer\_url) | Indicates for unmanaged OIDC config, the bucket URL | `string` | `null` | no |
| <a name="input_managed"></a> [managed](#input\_managed) | Indicates whether it is a Red Hat managed or unmanaged (Customer hosted) OIDC Configuration | `bool` | `true` | no |
| <a name="input_secret_arn"></a> [secret\_arn](#input\_secret\_arn) | Indicates for unmanaged OIDC config, the secret ARN | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | List of AWS resource tags to apply. | `map(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_oidc_config_id"></a> [oidc\_config\_id](#output\_oidc\_config\_id) | n/a |
| <a name="output_oidc_endpoint_url"></a> [oidc\_endpoint\_url](#output\_oidc\_endpoint\_url) | n/a |

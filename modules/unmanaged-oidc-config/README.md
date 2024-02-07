# unmanaged-oidc-config

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

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_s3_bucket"></a> [aws\_s3\_bucket](#module\_aws\_s3\_bucket) | terraform-aws-modules/s3-bucket/aws | n/a |
| <a name="module_aws_secrets_manager"></a> [aws\_secrets\_manager](#module\_aws\_secrets\_manager) | terraform-aws-modules/secrets-manager/aws | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_s3_object.discrover_doc_object](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.jwks_object](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| rhcs_rosa_oidc_config_input.oidc_input | resource |
| [aws_iam_policy_document.allow_access_from_another_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_tags"></a> [tags](#input\_tags) | List of AWS resource tags to apply. | `map(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_issuer_url"></a> [issuer\_url](#output\_issuer\_url) | n/a |
| <a name="output_secret_arn"></a> [secret\_arn](#output\_secret\_arn) | n/a |

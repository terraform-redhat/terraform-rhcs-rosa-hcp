# rosa-cluster-classic

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

No modules.

## Resources

| Name | Type |
|------|------|
| [rhcs_cluster_rosa_classic.rosa_sts_cluster](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/cluster_rosa_classic) | resource |
| [rhcs_cluster_wait.rosa_cluster](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/cluster_wait) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | n/a | `list(string)` | `null` | no |
| <a name="input_aws_private_link"></a> [aws\_private\_link](#input\_aws\_private\_link) | n/a | `bool` | `false` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | n/a | `string` | n/a | yes |
| <a name="input_controlplane_role_arn"></a> [controlplane\_role\_arn](#input\_controlplane\_role\_arn) | STS Role ARN with get secrets permission | `string` | n/a | yes |
| <a name="input_installer_role_arn"></a> [installer\_role\_arn](#input\_installer\_role\_arn) | n/a | `string` | n/a | yes |
| <a name="input_multi_az"></a> [multi\_az](#input\_multi\_az) | n/a | `bool` | `false` | no |
| <a name="input_oidc_config_id"></a> [oidc\_config\_id](#input\_oidc\_config\_id) | n/a | `string` | n/a | yes |
| <a name="input_openshift_version"></a> [openshift\_version](#input\_openshift\_version) | Desired version of OpenShift for the cluster, for example '4.1.0'. If version is greater than the currently running version, an upgrade will be scheduled. | `string` | n/a | yes |
| <a name="input_operator_role_prefix"></a> [operator\_role\_prefix](#input\_operator\_role\_prefix) | n/a | `string` | n/a | yes |
| <a name="input_private"></a> [private](#input\_private) | n/a | `bool` | `false` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | n/a | `list(string)` | `null` | no |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | The amount of the machine created in this machine pool. | `number` | `null` | no |
| <a name="input_support_role_arn"></a> [support\_role\_arn](#input\_support\_role\_arn) | STS Role ARN with get secrets permission | `string` | n/a | yes |
| <a name="input_worker_role_arn"></a> [worker\_role\_arn](#input\_worker\_role\_arn) | STS Role ARN with get secrets permission | `string` | n/a | yes |

## Outputs


| Name                                                               | Description             | Type     |
|--------------------------------------------------------------------|-------------------------|----------|
| <a name="cluster_id"></a> cluster_id | The ROSA STS cluster ID | `string` |

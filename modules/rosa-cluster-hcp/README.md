# rosa-cluster-hcp

## Introduction

This Terraform sub-module helps the provisioning and management of ROSA HCP clusters within AWS infrastructure. Prior to using this sub-module, ensure that AWS IAM roles and policies are already established in the account, along with the necessary OIDC configuration and provider settings.

This sub-module also includes the following resources:
- Default Ingress: enables the setup and management of the default ingress configuration, allowing seamless routing of external traffic to services deployed within the cluster.

## Example Usage

```
module "rosa_cluster_hcp" {
  source = "terraform-redhat/rosa-hcp/rhcs//modules/rosa-cluster-hcp"

  cluster_name           = "my-cluster"
  operator_role_prefix   = "my-operators"
  openshift_version      = "4.14.24"
  installer_role_arn     = "arn:aws:iam::012345678912:role/ManagedOpenShift-HCP-ROSA-Installer-Role"
  support_role_arn       = "arn:aws:iam::012345678912:role/ManagedOpenShift-HCP-ROSA-Support-Role"
  worker_role_arn        = "arn:aws:iam::012345678912:role/ManagedOpenShift-HCP-ROSA-Worker-Role"
  oidc_config_id         = "oidc-config-123"
  aws_subnet_ids         = ["subnet-1","subnet-2"]
  machine_cidr           = "10.0.0.0/16"
  service_cidr           = "172.30.0.0/16"
  pod_cidr               = "10.128.0.0/14"
  host_prefix            = "23"
  replicas               = 2
  compute_machine_type   = "m5.xlarge"
  aws_availability_zones = ["us-west-2a"]
}
```

<!-- BEGIN_AUTOMATED_TF_DOCS_BLOCK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.38.0 |
| <a name="requirement_rhcs"></a> [rhcs](#requirement\_rhcs) | >= 1.6.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.38.0 |
| <a name="provider_rhcs"></a> [rhcs](#provider\_rhcs) | >= 1.6.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [rhcs_cluster_rosa_hcp.rosa_hcp_cluster](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/cluster_rosa_hcp) | resource |
| [rhcs_hcp_cluster_autoscaler.cluster_autoscaler](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/hcp_cluster_autoscaler) | resource |
| [rhcs_hcp_default_ingress.default_ingress](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/hcp_default_ingress) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_subnet.provided_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_role_prefix"></a> [account\_role\_prefix](#input\_account\_role\_prefix) | User-defined prefix for all generated AWS resources (default "account-role-<random>") | `string` | `null` | no |
| <a name="input_additional_trust_bundle"></a> [additional\_trust\_bundle](#input\_additional\_trust\_bundle) | A string containing a PEM-encoded X.509 certificate bundle that will be added to the nodes' trusted certificate store. | `string` | `null` | no |
| <a name="input_admin_credentials_password"></a> [admin\_credentials\_password](#input\_admin\_credentials\_password) | Admin password that is created with the cluster. The password must contain at least 14 characters (ASCII-standard) without whitespaces including uppercase letters, lowercase letters, and numbers or symbols. | `string` | `null` | no |
| <a name="input_admin_credentials_username"></a> [admin\_credentials\_username](#input\_admin\_credentials\_username) | Admin username that is created with the cluster. auto generated username - "cluster-admin" | `string` | `null` | no |
| <a name="input_autoscaler_max_node_provision_time"></a> [autoscaler\_max\_node\_provision\_time](#input\_autoscaler\_max\_node\_provision\_time) | Maximum time cluster-autoscaler waits for node to be provisioned. | `string` | `null` | no |
| <a name="input_autoscaler_max_nodes_total"></a> [autoscaler\_max\_nodes\_total](#input\_autoscaler\_max\_nodes\_total) | Maximum number of nodes in all node groups. Cluster autoscaler will not grow the cluster beyond this number. | `number` | `null` | no |
| <a name="input_autoscaler_max_pod_grace_period"></a> [autoscaler\_max\_pod\_grace\_period](#input\_autoscaler\_max\_pod\_grace\_period) | Gives pods graceful termination time before scaling down. | `number` | `null` | no |
| <a name="input_autoscaler_pod_priority_threshold"></a> [autoscaler\_pod\_priority\_threshold](#input\_autoscaler\_pod\_priority\_threshold) | To allow users to schedule 'best-effort' pods, which shouldn't trigger Cluster Autoscaler actions, but only run when there are spare resources available. | `number` | `null` | no |
| <a name="input_aws_account_arn"></a> [aws\_account\_arn](#input\_aws\_account\_arn) | The ARN of the AWS account where all resources are created during the installation of the ROSA cluster. If no information is provided, the data will be retrieved from the currently connected account. | `string` | `null` | no |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | The AWS account identifier where all resources are created during the installation of the ROSA cluster. If no information is provided, the data will be retrieved from the currently connected account. | `string` | `null` | no |
| <a name="input_aws_additional_compute_security_group_ids"></a> [aws\_additional\_compute\_security\_group\_ids](#input\_aws\_additional\_compute\_security\_group\_ids) | The additional security group IDs to be added to the default worker machine pool. | `list(string)` | `null` | no |
| <a name="input_aws_availability_zones"></a> [aws\_availability\_zones](#input\_aws\_availability\_zones) | The AWS availability zones where instances of the default worker machine pool are deployed. Leave empty for the installer to pick availability zones | `list(string)` | `[]` | no |
| <a name="input_aws_billing_account_id"></a> [aws\_billing\_account\_id](#input\_aws\_billing\_account\_id) | The AWS billing account identifier where all resources are billed. If no information is provided, the data will be retrieved from the currently connected account. | `string` | `null` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The full name of the AWS region used for the ROSA cluster installation, for example 'us-east-1'. If no information is provided, the data will be retrieved from the currently connected account. | `string` | `null` | no |
| <a name="input_aws_subnet_ids"></a> [aws\_subnet\_ids](#input\_aws\_subnet\_ids) | The Subnet IDs to use when installing the cluster. | `list(string)` | n/a | yes |
| <a name="input_cluster_autoscaler_enabled"></a> [cluster\_autoscaler\_enabled](#input\_cluster\_autoscaler\_enabled) | Enable Autoscaler for this cluster. This resource is currently unavailable and using will result in error 'Autoscaler configuration is not available' | `bool` | `false` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the cluster. After the creation of the resource, it is not possible to update the attribute value. | `string` | n/a | yes |
| <a name="input_compute_machine_type"></a> [compute\_machine\_type](#input\_compute\_machine\_type) | Identifies the Instance type used by the default worker machine pool e.g. `m5.xlarge`. Use the `rhcs_machine_types` data source to find the possible values. | `string` | `null` | no |
| <a name="input_create_admin_user"></a> [create\_admin\_user](#input\_create\_admin\_user) | To create cluster admin user with default username `cluster-admin` and generated password. It will be ignored if `admin_credentials_username` or `admin_credentials_password` is set. (default: false) | `bool` | `null` | no |
| <a name="input_default_ingress_listening_method"></a> [default\_ingress\_listening\_method](#input\_default\_ingress\_listening\_method) | Listening Method for ingress. Options are ["internal", "external"]. Default is "external". When empty is set based on private variable. | `string` | `""` | no |
| <a name="input_destroy_timeout"></a> [destroy\_timeout](#input\_destroy\_timeout) | Maximum duration in minutes to allow for destroying resources. (Default: 60 minutes) | `number` | `null` | no |
| <a name="input_disable_waiting_in_destroy"></a> [disable\_waiting\_in\_destroy](#input\_disable\_waiting\_in\_destroy) | Disable addressing cluster state in the destroy resource. Default value is false, and so a `destroy` will wait for the cluster to be deleted. | `bool` | `null` | no |
| <a name="input_ec2_metadata_http_tokens"></a> [ec2\_metadata\_http\_tokens](#input\_ec2\_metadata\_http\_tokens) | Should cluster nodes use both v1 and v2 endpoints or just v2 endpoint of EC2 Instance Metadata Service (IMDS). Available since OpenShift 4.11.0. | `string` | `"optional"` | no |
| <a name="input_etcd_encryption"></a> [etcd\_encryption](#input\_etcd\_encryption) | Add etcd encryption. By default etcd data is encrypted at rest. This option configures etcd encryption on top of existing storage encryption. | `bool` | `null` | no |
| <a name="input_etcd_kms_key_arn"></a> [etcd\_kms\_key\_arn](#input\_etcd\_kms\_key\_arn) | The key ARN is the Amazon Resource Name (ARN) of a CMK. It is a unique, fully qualified identifier for the CMK. A key ARN includes the AWS account, Region, and the key ID. | `string` | `null` | no |
| <a name="input_host_prefix"></a> [host\_prefix](#input\_host\_prefix) | Subnet prefix length to assign to each individual node. For example, if host prefix is set to "23", then each node is assigned a /23 subnet out of the given CIDR. | `number` | `null` | no |
| <a name="input_http_proxy"></a> [http\_proxy](#input\_http\_proxy) | A proxy URL to use for creating HTTP connections outside the cluster. The URL scheme must be http. | `string` | `null` | no |
| <a name="input_https_proxy"></a> [https\_proxy](#input\_https\_proxy) | A proxy URL to use for creating HTTPS connections outside the cluster. | `string` | `null` | no |
| <a name="input_installer_role_arn"></a> [installer\_role\_arn](#input\_installer\_role\_arn) | The Amazon Resource Name (ARN) associated with the AWS IAM role used by the ROSA installer. | `string` | `null` | no |
| <a name="input_is_zero_ingress"></a> [is\_zero\_ingress](#input\_is\_zero\_ingress) | Indicates use of zero ingress resources | `bool` | `false` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | The key ARN is the Amazon Resource Name (ARN) of a CMK. It is a unique, fully qualified identifier for the CMK. A key ARN includes the AWS account, Region, and the key ID. | `string` | `null` | no |
| <a name="input_machine_cidr"></a> [machine\_cidr](#input\_machine\_cidr) | Block of IP addresses used by OpenShift while installing the cluster, for example "10.0.0.0/16". | `string` | `null` | no |
| <a name="input_no_proxy"></a> [no\_proxy](#input\_no\_proxy) | A comma-separated list of destination domain names, domains, IP addresses or other network CIDRs to exclude proxying. | `string` | `null` | no |
| <a name="input_oidc_config_id"></a> [oidc\_config\_id](#input\_oidc\_config\_id) | The unique identifier associated with users authenticated through OpenID Connect (OIDC) within the ROSA cluster. | `string` | n/a | yes |
| <a name="input_openshift_version"></a> [openshift\_version](#input\_openshift\_version) | Desired version of OpenShift for the cluster, for example '4.1.0'. If version is greater than the currently running version, an upgrade will be scheduled. | `string` | n/a | yes |
| <a name="input_operator_role_prefix"></a> [operator\_role\_prefix](#input\_operator\_role\_prefix) | A designated prefix used for the creation of AWS IAM roles asso:willciated with operators within the ROSA environment. | `string` | n/a | yes |
| <a name="input_path"></a> [path](#input\_path) | The arn path for the account/operator roles as well as their policies. Must begin and end with '/'. | `string` | `"/"` | no |
| <a name="input_pod_cidr"></a> [pod\_cidr](#input\_pod\_cidr) | Block of IP addresses from which Pod IP addresses are allocated, for example "10.128.0.0/14". | `string` | `null` | no |
| <a name="input_private"></a> [private](#input\_private) | Restrict master API endpoint and application routes to direct, private connectivity. (default: false) | `bool` | `false` | no |
| <a name="input_properties"></a> [properties](#input\_properties) | User defined properties. | `map(string)` | `null` | no |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | Number of worker nodes to provision. This attribute is applicable solely when autoscaling is disabled. Single zone clusters need at least 2 nodes, multizone clusters need at least 3 nodes. Hosted clusters require that the number of worker nodes be a multiple of the number of private subnets. (default: 2) | `number` | `null` | no |
| <a name="input_service_cidr"></a> [service\_cidr](#input\_service\_cidr) | Block of IP addresses for services, for example "172.30.0.0/16". | `string` | `null` | no |
| <a name="input_support_role_arn"></a> [support\_role\_arn](#input\_support\_role\_arn) | The Amazon Resource Name (ARN) associated with the AWS IAM role used by Red Hat SREs to enable access to the cluster account in order to provide support. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Apply user defined tags to all cluster resources created in AWS. After the creation of the cluster is completed, it is not possible to update this attribute. | `map(string)` | `null` | no |
| <a name="input_upgrade_acknowledgements_for"></a> [upgrade\_acknowledgements\_for](#input\_upgrade\_acknowledgements\_for) | Indicates acknowledgement of agreements required to upgrade the cluster version between minor versions (e.g. a value of "4.12" indicates acknowledgement of any agreements required to upgrade to OpenShift 4.12.z from 4.11 or before). | `string` | `null` | no |
| <a name="input_wait_for_create_complete"></a> [wait\_for\_create\_complete](#input\_wait\_for\_create\_complete) | Wait until the cluster is either in a ready state or in an error state. The waiter has a timeout of 20 minutes. (default: true) | `bool` | `true` | no |
| <a name="input_wait_for_std_compute_nodes_complete"></a> [wait\_for\_std\_compute\_nodes\_complete](#input\_wait\_for\_std\_compute\_nodes\_complete) | Wait until the cluster standard compute nodes are available. The waiter has a timeout of 60 minutes. (default: true) | `bool` | `true` | no |
| <a name="input_worker_role_arn"></a> [worker\_role\_arn](#input\_worker\_role\_arn) | The Amazon Resource Name (ARN) associated with the AWS IAM role that will be used by the cluster's compute instances. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_admin_password"></a> [cluster\_admin\_password](#output\_cluster\_admin\_password) | The password of the admin user. |
| <a name="output_cluster_admin_username"></a> [cluster\_admin\_username](#output\_cluster\_admin\_username) | The username of the admin user. |
| <a name="output_cluster_api_url"></a> [cluster\_api\_url](#output\_cluster\_api\_url) | The URL of the API server. |
| <a name="output_cluster_console_url"></a> [cluster\_console\_url](#output\_cluster\_console\_url) | The URL of the console. |
| <a name="output_cluster_current_version"></a> [cluster\_current\_version](#output\_cluster\_current\_version) | The currently running version of OpenShift on the cluster, for example '4.11.0'. |
| <a name="output_cluster_domain"></a> [cluster\_domain](#output\_cluster\_domain) | The DNS domain of cluster. |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | The identification of the cluster in OCM |
| <a name="output_cluster_state"></a> [cluster\_state](#output\_cluster\_state) | The state of the cluster. |
<!-- END_AUTOMATED_TF_DOCS_BLOCK -->
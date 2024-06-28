# terraform-rhcs-rosa-hcp
Terraform module which creates ROSA HCP cluster

## Introduction

This module serves as a comprehensive solution for deploying, configuring and managing Red Hat OpenShift on AWS (ROSA) Hosted Control Plane (HCP) clusters within your AWS environment. With a focus on simplicity and efficiency, this module streamlines the process of setting up and maintaining ROSA HCP clusters, enabling users to use the power of OpenShift on AWS infrastructure effortlessly.

## Example Usage

```
module "hcp" {
  source = "terraform-redhat/rosa-hcp/rhcs"
  version = "1.6.2"

  cluster_name           = "my-cluster"
  openshift_version      = "4.14.24"
  machine_cidr           = "10.0.0.0/16"
  aws_subnet_ids         = ["subnet-1", "subnet-2"]
  aws_availability_zones = ["us-west-2a"]
  replicas               = 2

  // STS configuration
  create_account_roles  = true
  account_role_prefix   = "my-cluster-account"
  create_oidc           = true
  create_operator_roles = true
  operator_role_prefix  = "my-cluster-operator"
}
```

## Sub-modules

Sub-modules included in this module:

- account-iam-resource: Handles the provisioning of Identity and Access Management (IAM) resources required for managing access and permissions in the AWS account associated with the ROSA HCP cluster.
- idp: Responsible for configuring Identity Providers (IDPs) within the ROSA HCP cluster, faciliting seamless integration with external authentication system such as Github (GH), GitLab, Google, HTPasswd, LDAP and OpenID Connect (OIDC).
- machine-pool: Facilitates the management of machine pools within the ROSA HCP cluster, enabling users to scale resources and adjust specifications based on workload demands.
- oidc-config-and-provider: Manages the configuration of OpenID Connect (OIDC) hosted files and providers for ROSA HCP clusters, enabling secure authentication and access control mechanisms for operator roles.
- operator-roles: Oversees the management of roles assigned to operators within the ROSA HCP cluster, enabling to perform required actions with appropriate permissions on the lifecyle of a cluster.
- rosa-cluster-hcp: Handles the core configuration and provisioning of the ROSA HCP cluster, including cluster networking, security settings and other essential components.
- vpc: Handles the configuration and provisioning of the Virtucal Private Cloud (VPC) infrastracture required for hosting the ROSA HCP cluster and it's associated resources.

The primary sub-modules responsible for ROSA HCP cluster creation includes optional configurations for setting up account roles, operator roles and OIDC config/provider. This comprehensive module handles the entire process of provisioning and configuring ROSA HCP clusters in your AWS environment.

## Pre-requisites

* [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) (1.4.6+) must be installed.
* An [AWS account](https://aws.amazon.com/free/?all-free-tier) and the [associated credentials](https://docs.aws.amazon.com/IAM/latest/UserGuide/security-creds.html) that allow you to create resources. These credentials must be configured for the AWS provider (see [Authentication and Configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration) section in AWS terraform provider documentation.)
* The [ROSA getting started AWS prerequisites](https://console.redhat.com/openshift/create/rosa/getstarted) must be completed.
* A valid [OpenShift Cluster Manager API Token](https://console.redhat.com/openshift/token) must be configured (see [Authentication and configuration](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs#authentication-and-configuration) for more information).

We recommend you install the following CLI tools:

* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* [ROSA CLI](https://docs.openshift.com/rosa/cli_reference/rosa_cli/rosa-get-started-cli.html)
* [Openshift CLI (oc)](https://docs.openshift.com/rosa/cli_reference/openshift_cli/getting-started-cli.html)

<!-- BEGIN_AUTOMATED_TF_DOCS_BLOCK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.38.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.0.0 |
| <a name="requirement_rhcs"></a> [rhcs](#requirement\_rhcs) | = 1.6.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.38.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_account_iam_resources"></a> [account\_iam\_resources](#module\_account\_iam\_resources) | ./modules/account-iam-resources | n/a |
| <a name="module_oidc_config_and_provider"></a> [oidc\_config\_and\_provider](#module\_oidc\_config\_and\_provider) | ./modules/oidc-config-and-provider | n/a |
| <a name="module_operator_roles"></a> [operator\_roles](#module\_operator\_roles) | ./modules/operator-roles | n/a |
| <a name="module_rosa_cluster_hcp"></a> [rosa\_cluster\_hcp](#module\_rosa\_cluster\_hcp) | ./modules/rosa-cluster-hcp | n/a |

## Resources

| Name | Type |
|------|------|
| [null_resource.validations](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_role_prefix"></a> [account\_role\_prefix](#input\_account\_role\_prefix) | User-defined prefix for all generated AWS resources (default "account-role-<random>") | `string` | `null` | no |
| <a name="input_additional_trust_bundle"></a> [additional\_trust\_bundle](#input\_additional\_trust\_bundle) | A string containing a PEM-encoded X.509 certificate bundle that will be added to the nodes' trusted certificate store. | `string` | `null` | no |
| <a name="input_autoscaler_max_node_provision_time"></a> [autoscaler\_max\_node\_provision\_time](#input\_autoscaler\_max\_node\_provision\_time) | Maximum time cluster-autoscaler waits for node to be provisioned. | `string` | `null` | no |
| <a name="input_autoscaler_max_nodes_total"></a> [autoscaler\_max\_nodes\_total](#input\_autoscaler\_max\_nodes\_total) | Maximum number of nodes in all node groups. Cluster autoscaler will not grow the cluster beyond this number. | `number` | `null` | no |
| <a name="input_autoscaler_max_pod_grace_period"></a> [autoscaler\_max\_pod\_grace\_period](#input\_autoscaler\_max\_pod\_grace\_period) | Gives pods graceful termination time before scaling down. | `number` | `null` | no |
| <a name="input_autoscaler_pod_priority_threshold"></a> [autoscaler\_pod\_priority\_threshold](#input\_autoscaler\_pod\_priority\_threshold) | To allow users to schedule 'best-effort' pods, which shouldn't trigger Cluster Autoscaler actions, but only run when there are spare resources available. | `number` | `null` | no |
| <a name="input_aws_availability_zones"></a> [aws\_availability\_zones](#input\_aws\_availability\_zones) | The AWS availability zones where instances of the default worker machine pool are deployed. Leave empty for the installer to pick availability zones | `list(string)` | `[]` | no |
| <a name="input_aws_billing_account_id"></a> [aws\_billing\_account\_id](#input\_aws\_billing\_account\_id) | The AWS billing account identifier where all resources are billed. If no information is provided, the data will be retrieved from the currently connected account. | `string` | `null` | no |
| <a name="input_aws_subnet_ids"></a> [aws\_subnet\_ids](#input\_aws\_subnet\_ids) | The Subnet IDs to use when installing the cluster. | `list(string)` | n/a | yes |
| <a name="input_cluster_autoscaler_enabled"></a> [cluster\_autoscaler\_enabled](#input\_cluster\_autoscaler\_enabled) | Enable Autoscaler for this cluster. This resource is currently unavailable and using will result in error 'Autoscaler configuration is not available' | `bool` | `false` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the cluster. After the creation of the resource, it is not possible to update the attribute value. | `string` | n/a | yes |
| <a name="input_compute_machine_type"></a> [compute\_machine\_type](#input\_compute\_machine\_type) | Identifies the Instance type used by the default worker machine pool e.g. `m5.xlarge`. Use the `rhcs_machine_types` data source to find the possible values. | `string` | `null` | no |
| <a name="input_create_account_roles"></a> [create\_account\_roles](#input\_create\_account\_roles) | Create the aws account roles for rosa | `bool` | `false` | no |
| <a name="input_create_oidc"></a> [create\_oidc](#input\_create\_oidc) | Create the oidc resources. This value should not be updated, please create a new resource instead or utilize the submodule to create a new oidc config | `bool` | `false` | no |
| <a name="input_create_operator_roles"></a> [create\_operator\_roles](#input\_create\_operator\_roles) | Create the aws account roles for rosa | `bool` | `false` | no |
| <a name="input_default_ingress_listening_method"></a> [default\_ingress\_listening\_method](#input\_default\_ingress\_listening\_method) | Listening Method for ingress. Options are ["internal", "external"]. Default is "external". When empty is set based on private variable. | `string` | `""` | no |
| <a name="input_destroy_timeout"></a> [destroy\_timeout](#input\_destroy\_timeout) | Maximum duration in minutes to allow for destroying resources. (Default: 60 minutes) | `number` | `null` | no |
| <a name="input_disable_waiting_in_destroy"></a> [disable\_waiting\_in\_destroy](#input\_disable\_waiting\_in\_destroy) | Disable addressing cluster state in the destroy resource. Default value is false, and so a `destroy` will wait for the cluster to be deleted. | `bool` | `null` | no |
| <a name="input_etcd_encryption"></a> [etcd\_encryption](#input\_etcd\_encryption) | Add etcd encryption. By default etcd data is encrypted at rest. This option configures etcd encryption on top of existing storage encryption. | `bool` | `null` | no |
| <a name="input_etcd_kms_key_arn"></a> [etcd\_kms\_key\_arn](#input\_etcd\_kms\_key\_arn) | The key ARN is the Amazon Resource Name (ARN) of a CMK. It is a unique, fully qualified identifier for the CMK. A key ARN includes the AWS account, Region, and the key ID. | `string` | `null` | no |
| <a name="input_host_prefix"></a> [host\_prefix](#input\_host\_prefix) | Subnet prefix length to assign to each individual node. For example, if host prefix is set to "23", then each node is assigned a /23 subnet out of the given CIDR. | `number` | `null` | no |
| <a name="input_http_proxy"></a> [http\_proxy](#input\_http\_proxy) | A proxy URL to use for creating HTTP connections outside the cluster. The URL scheme must be http. | `string` | `null` | no |
| <a name="input_https_proxy"></a> [https\_proxy](#input\_https\_proxy) | A proxy URL to use for creating HTTPS connections outside the cluster. | `string` | `null` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | The key ARN is the Amazon Resource Name (ARN) of a CMK. It is a unique, fully qualified identifier for the CMK. A key ARN includes the AWS account, Region, and the key ID. | `string` | `null` | no |
| <a name="input_machine_cidr"></a> [machine\_cidr](#input\_machine\_cidr) | Block of IP addresses used by OpenShift while installing the cluster, for example "10.0.0.0/16". | `string` | `null` | no |
| <a name="input_managed_oidc"></a> [managed\_oidc](#input\_managed\_oidc) | OIDC type managed or unmanaged oidc. Only active when create\_oidc also enabled. This value should not be updated, please create a new resource instead | `bool` | `true` | no |
| <a name="input_no_proxy"></a> [no\_proxy](#input\_no\_proxy) | A comma-separated list of destination domain names, domains, IP addresses or other network CIDRs to exclude proxying. | `string` | `null` | no |
| <a name="input_oidc_config_id"></a> [oidc\_config\_id](#input\_oidc\_config\_id) | The unique identifier associated with users authenticated through OpenID Connect (OIDC) within the ROSA cluster. If create\_oidc is false this attribute is required. | `string` | `null` | no |
| <a name="input_oidc_endpoint_url"></a> [oidc\_endpoint\_url](#input\_oidc\_endpoint\_url) | Registered OIDC configuration issuer URL, added as the trusted relationship to the operator roles. Valid only when create\_oidc is false. | `string` | `null` | no |
| <a name="input_openshift_version"></a> [openshift\_version](#input\_openshift\_version) | Desired version of OpenShift for the cluster, for example '4.1.0'. If version is greater than the currently running version, an upgrade will be scheduled. | `string` | n/a | yes |
| <a name="input_operator_role_prefix"></a> [operator\_role\_prefix](#input\_operator\_role\_prefix) | User-defined prefix for generated AWS operator policies. Use "account-role-prefix" in case no value provided. | `string` | `null` | no |
| <a name="input_path"></a> [path](#input\_path) | The arn path for the account/operator roles as well as their policies. Must begin and end with '/'. | `string` | `"/"` | no |
| <a name="input_permissions_boundary"></a> [permissions\_boundary](#input\_permissions\_boundary) | The ARN of the policy that is used to set the permissions boundary for the IAM roles in STS clusters. | `string` | `""` | no |
| <a name="input_pod_cidr"></a> [pod\_cidr](#input\_pod\_cidr) | Block of IP addresses from which Pod IP addresses are allocated, for example "10.128.0.0/14". | `string` | `null` | no |
| <a name="input_private"></a> [private](#input\_private) | Restrict master API endpoint and application routes to direct, private connectivity. (default: false) | `bool` | `false` | no |
| <a name="input_properties"></a> [properties](#input\_properties) | User defined properties. | `map(string)` | `null` | no |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | Number of worker nodes to provision. This attribute is applicable solely when autoscaling is disabled. Single zone clusters need at least 2 nodes, multizone clusters need at least 3 nodes. Hosted clusters require that the number of worker nodes be a multiple of the number of private subnets. (default: 2) | `number` | `null` | no |
| <a name="input_service_cidr"></a> [service\_cidr](#input\_service\_cidr) | Block of IP addresses for services, for example "172.30.0.0/16". | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Apply user defined tags to all cluster resources created in AWS. After the creation of the cluster is completed, it is not possible to update this attribute. | `map(string)` | `null` | no |
| <a name="input_upgrade_acknowledgements_for"></a> [upgrade\_acknowledgements\_for](#input\_upgrade\_acknowledgements\_for) | Indicates acknowledgement of agreements required to upgrade the cluster version between minor versions (e.g. a value of "4.12" indicates acknowledgement of any agreements required to upgrade to OpenShift 4.12.z from 4.11 or before). | `bool` | `null` | no |
| <a name="input_wait_for_create_complete"></a> [wait\_for\_create\_complete](#input\_wait\_for\_create\_complete) | Wait until the cluster is either in a ready state or in an error state. The waiter has a timeout of 20 minutes. (default: true) | `bool` | `true` | no |
| <a name="input_wait_for_std_compute_nodes_complete"></a> [wait\_for\_std\_compute\_nodes\_complete](#input\_wait\_for\_std\_compute\_nodes\_complete) | Wait until the initial set of machine pools to be available. The waiter has a timeout of 60 minutes. (default: true) | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | Unique identifier of the cluster. |
<!-- END_AUTOMATED_TF_DOCS_BLOCK -->

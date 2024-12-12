# Private ROSA HCP with shared VPC where the hosted zones are in cluster owner account example

## Introduction

This is a Terraform manifest example for creating a Red Hat OpenShift Service on AWS (ROSA) cluster. This example provides a structured configuration template that demonstrates how to deploy a ROSA cluster within your AWS environment by using Terraform.

This example includes:
- A ROSA cluster with private access.
- A pre-existing shared VPC within a separate AWS account, hosted zones will be created in the cluster owner account instead.
- A bastion host EC2 instance that allows to reach the private cluster.

## Prerequisites

* You have installed the [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) (1.4.6+).
* You have an [AWS account](https://aws.amazon.com/free/?all-free-tier) and [associated credentials](https://docs.aws.amazon.com/IAM/latest/UserGuide/security-creds.html) that you can use to create resources. You must supply the credentials for this account through the appropriate input variables in the example.
* You have a secondary AWS account for the shared VPC resources. You must supply the credentials for this account through the appropriate input variables in the example.
* You have completed the [ROSA getting started AWS prerequisites](https://console.redhat.com/openshift/create/rosa/getstarted).
* You have a valid [OpenShift Cluster Manager API Token](https://console.redhat.com/openshift/token) configured (see [Authentication and configuration](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs#authentication-and-configuration) for more info).
* Recommended: You have installed the following CLI tools:
    * [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
    * [ROSA CLI](https://docs.openshift.com/rosa/cli_reference/rosa_cli/rosa-get-started-cli.html)
    * [Openshift CLI (oc)](https://docs.openshift.com/rosa/cli_reference/openshift_cli/getting-started-cli.html)

For more info about shared VPC, see [Configuring a shared VPC for ROSA clusters](https://docs.openshift.com/rosa/rosa_install_access_delete_clusters/rosa-shared-vpc-config.html).

## Example Usage

```
data "aws_partition" "current" {}
data "aws_region" "current" {}
provider "aws" {
  alias = "cluster-owner"

  access_key               = var.cluster_owner_aws_access_key_id
  secret_key               = var.cluster_owner_aws_secret_access_key
  region                   = data.aws_region.current.name
  profile                  = var.cluster_owner_aws_profile
  shared_credentials_files = var.cluster_owner_aws_shared_credentials_files
}

locals {
  account_role_prefix          = "${var.cluster_name}-acc"
  operator_role_prefix         = "${var.cluster_name}-op"
  shared_resources_name_prefix = var.cluster_name
  shared_route53_role_name     = substr("${local.shared_resources_name_prefix}-shared-route53-role", 0, 64)
  shared_vpce_role_name        = substr("${local.shared_resources_name_prefix}-shared-vpce-role", 0, 64)
  # Required to generate the expected names for the shared vpc role arns
  # There is a cyclic dependency on the shared vpc role arns and the installer,control-plane,ingress roles
  # that is because AWS will not accept to include these into the trust policy without first creating it
  # however, will allow to generate a permission policy with these values before the creation of the roles
  shared_vpc_roles_arns = {
    "route53" : "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.shared_vpc.account_id}:role/${local.shared_route53_role_name}",
    "vpce" : "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.shared_vpc.account_id}:role/${local.shared_vpce_role_name}"
  }
}

data "aws_caller_identity" "current" {
  provider = aws.cluster-owner
}

##############################################################
# Account roles includes IAM roles and IAM policies
##############################################################
module "account_iam_resources" {
  source = "../../modules/account-iam-resources"
  providers = {
    aws = aws.cluster-owner
  }

  account_role_prefix        = local.account_role_prefix
  create_shared_vpc_policies = true
  shared_vpc_roles           = local.shared_vpc_roles_arns
}

############################
# OIDC provider
############################
module "oidc_config_and_provider" {
  source = "../../modules/oidc-config-and-provider"
  providers = {
    aws = aws.cluster-owner
  }

  managed = true
}

############################
# operator roles
############################
module "operator_roles" {
  source = "../../modules/operator-roles"
  providers = {
    aws = aws.cluster-owner
  }

  operator_role_prefix       = local.operator_role_prefix
  path                       = module.account_iam_resources.path
  oidc_endpoint_url          = module.oidc_config_and_provider.oidc_endpoint_url
  create_shared_vpc_policies = false
  shared_vpc_roles           = local.shared_vpc_roles_arns
}

############################
# dns reservation
############################
resource "rhcs_dns_domain" "dns_domain" {
  cluster_arch = "hcp"
}

############################
# shared-vpc-resources
############################
provider "aws" {
  alias = "network-owner"

  access_key               = var.network_owner_aws_access_key_id
  secret_key               = var.network_owner_aws_secret_access_key
  region                   = data.aws_region.current.name
  profile                  = var.network_owner_aws_profile
  shared_credentials_files = var.network_owner_aws_shared_credentials_files
}

data "aws_caller_identity" "shared_vpc" {
  provider = aws.network-owner
}

module "vpc" {
  source = "../../modules/vpc"

  providers = {
    aws = aws.network-owner
  }

  name_prefix              = local.shared_resources_name_prefix
  availability_zones_count = 1
}

module "shared-vpc-resources" {
  source = "../../modules/shared-vpc-resources"

  providers = {
    aws = aws.network-owner
  }

  cluster_name                            = var.cluster_name
  account_roles_prefix                    = module.account_iam_resources.account_role_prefix
  operator_roles_prefix                   = module.operator_roles.operator_role_prefix
  ingress_private_hosted_zone_base_domain = rhcs_dns_domain.dns_domain.id
  name_prefix                             = local.shared_resources_name_prefix
  target_aws_account                      = data.aws_caller_identity.current.account_id
  subnets                                 = concat(module.vpc.private_subnets, module.vpc.public_subnets)
  vpc_id                                  = module.vpc.vpc_id
}

# Public elb tags for the shared subnets
resource "aws_ec2_tag" "tag_public_subnets" {
  provider    = aws.cluster-owner
  count       = length(module.vpc.public_subnets)
  resource_id = module.vpc.public_subnets[count.index]
  key         = "kubernetes.io/role/elb"
  value       = ""
}

# Private elb tags for the shared subnets
resource "aws_ec2_tag" "tag_private_subnets" {
  provider    = aws.cluster-owner
  count       = length(module.vpc.private_subnets)
  resource_id = module.vpc.private_subnets[count.index]
  key         = "kubernetes.io/role/internal-elb"
  value       = ""
}

############################
# ROSA STS cluster
############################
module "rosa_cluster_hcp" {
  source = "../../modules/rosa-cluster-hcp"
  providers = {
    aws = aws.cluster-owner
  }

  cluster_name               = var.cluster_name
  openshift_version          = var.openshift_version
  version_channel_group      = var.version_channel_group
  machine_cidr               = module.vpc.cidr_block
  aws_subnet_ids             = module.shared-vpc-resources.shared_subnets
  replicas                   = 2
  create_admin_user          = true
  admin_credentials_username = "admin"
  admin_credentials_password = random_password.password.result
  ec2_metadata_http_tokens   = "required"
  aws_billing_account_id     = var.aws_billing_account_id

  // STS configuration
  oidc_config_id       = module.oidc_config_and_provider.oidc_config_id
  account_role_prefix  = module.account_iam_resources.account_role_prefix
  operator_role_prefix = module.operator_roles.operator_role_prefix
  shared_vpc = {
    ingress_private_hosted_zone_id                = module.shared-vpc-resources.ingress_private_hosted_zone_id
    internal_communication_private_hosted_zone_id = module.shared-vpc-resources.hcp_internal_communication_private_hosted_zone_id
    route53_role_arn                              = module.shared-vpc-resources.route53_role
    vpce_role_arn                                 = module.shared-vpc-resources.vpce_role
  }
  base_dns_domain                   = rhcs_dns_domain.dns_domain.id
  aws_additional_allowed_principals = [module.shared-vpc-resources.route53_role, module.shared-vpc-resources.vpce_role]
}

resource "random_password" "password" {
  length      = 14
  special     = true
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

locals {
  network_owner_aws_credentials_provided = length(var.network_owner_aws_access_key_id) > 0 && length(var.network_owner_aws_secret_access_key) > 0
  network_owner_aws_profile_provided     = length(var.network_owner_aws_profile) > 0
  cluster_owner_aws_credentials_provided = length(var.cluster_owner_aws_access_key_id) > 0 && length(var.cluster_owner_aws_secret_access_key) > 0
  cluster_owner_aws_profile_provided     = length(var.cluster_owner_aws_profile) > 0
}

resource "null_resource" "validations" {
  lifecycle {
    precondition {
      condition     = (local.network_owner_aws_credentials_provided == false && local.network_owner_aws_profile_provided == false) == false
      error_message = "AWS credentials for the network-owner account must be provided. This can provided with \"var.network_owner_aws_access_key_id\" and \"var.network_owner_aws_secret_access_key\" or with existing profile \"var.network_owner_aws_profile\""
    }
    precondition {
      condition     = (local.cluster_owner_aws_credentials_provided == false && local.cluster_owner_aws_profile_provided == false) == false
      error_message = "AWS credentials for the cluster-owner account must be provided. This can provided with \"var.cluster_owner_aws_access_key_id\" and \"var.cluster_owner_aws_secret_access_key\" or with existing profile \"var.cluster_owner_aws_profile\""
    }
  }
}
```

<!-- BEGIN_AUTOMATED_TF_DOCS_BLOCK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 2.0 |
| <a name="requirement_rhcs"></a> [rhcs](#requirement\_rhcs) | = 1.6.8-prerelease.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |
| <a name="provider_aws.cluster-owner"></a> [aws.cluster-owner](#provider\_aws.cluster-owner) | >= 4.0 |
| <a name="provider_aws.network-owner"></a> [aws.network-owner](#provider\_aws.network-owner) | >= 4.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.0.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 2.0 |
| <a name="provider_rhcs"></a> [rhcs](#provider\_rhcs) | = 1.6.8-prerelease.1 |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_account_iam_resources"></a> [account\_iam\_resources](#module\_account\_iam\_resources) | ../../modules/account-iam-resources | n/a |
| <a name="module_bastion_host"></a> [bastion\_host](#module\_bastion\_host) | ../../modules/bastion-host | n/a |
| <a name="module_cluster_owner_vpc"></a> [cluster\_owner\_vpc](#module\_cluster\_owner\_vpc) | ../../modules/vpc | n/a |
| <a name="module_oidc_config_and_provider"></a> [oidc\_config\_and\_provider](#module\_oidc\_config\_and\_provider) | ../../modules/oidc-config-and-provider | n/a |
| <a name="module_operator_roles"></a> [operator\_roles](#module\_operator\_roles) | ../../modules/operator-roles | n/a |
| <a name="module_rosa_cluster_hcp"></a> [rosa\_cluster\_hcp](#module\_rosa\_cluster\_hcp) | ../../modules/rosa-cluster-hcp | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../modules/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_tag.tag_private_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_tag) | resource |
| [aws_iam_policy.route53_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.vpce_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.route53_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.vpce_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.route_53_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.vpce_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_ram_principal_association.shared_vpc_resource_share](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_principal_association) | resource |
| [aws_ram_resource_association.shared_vpc_resource_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_association) | resource |
| [aws_ram_resource_share.shared_vpc_resource_share](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_share) | resource |
| [aws_route53_vpc_association_authorization.hcp_internal_communication_hosted_zone_association_auth](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_vpc_association_authorization) | resource |
| [aws_route53_vpc_association_authorization.ingress_private_hosted_zone_association_auth](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_vpc_association_authorization) | resource |
| [aws_route53_zone.hcp_internal_communication_hosted_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone.ingress_private_hosted_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone_association.hcp_internal_communication_hosted_zone_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone_association) | resource |
| [aws_route53_zone_association.ingress_private_hosted_zone_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone_association) | resource |
| [null_resource.validations](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [rhcs_dns_domain.dns_domain](https://registry.terraform.io/providers/terraform-redhat/rhcs/1.6.8-prerelease.1/docs/resources/dns_domain) | resource |
| [time_sleep.shared_resources_propagation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_ami.rhel9](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.cluster_owner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_caller_identity.network_owner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.cluster_owner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_partition.network_owner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_billing_account_id"></a> [aws\_billing\_account\_id](#input\_aws\_billing\_account\_id) | The AWS billing account identifier where all resources are billed. If no information is provided, the data will be retrieved from the currently connected account. | `string` | `null` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the cluster. After the creation of the resource, it is not possible to update the attribute value. | `string` | n/a | yes |
| <a name="input_cluster_owner_aws_access_key_id"></a> [cluster\_owner\_aws\_access\_key\_id](#input\_cluster\_owner\_aws\_access\_key\_id) | The access key provides access to AWS services and is associated with the shared-vpc AWS account. | `string` | `""` | no |
| <a name="input_cluster_owner_aws_profile"></a> [cluster\_owner\_aws\_profile](#input\_cluster\_owner\_aws\_profile) | The name of the AWS profile configured in the AWS credentials file (typically located at ~/.aws/credentials). This profile contains the access key, secret key, and optional session token associated with the shared-vpc AWS account. | `string` | `""` | no |
| <a name="input_cluster_owner_aws_secret_access_key"></a> [cluster\_owner\_aws\_secret\_access\_key](#input\_cluster\_owner\_aws\_secret\_access\_key) | The secret key paired with the access key. Together, they provide the necessary credentials for Terraform to authenticate with the shared-vpc AWS account and manage resources securely. | `string` | `""` | no |
| <a name="input_cluster_owner_aws_shared_credentials_files"></a> [cluster\_owner\_aws\_shared\_credentials\_files](#input\_cluster\_owner\_aws\_shared\_credentials\_files) | List of files path to the AWS shared credentials file. This file typically contains AWS access keys and secret keys and is used when authenticating with AWS using profiles (default file located at ~/.aws/credentials). | `list(string)` | `null` | no |
| <a name="input_network_owner_aws_access_key_id"></a> [network\_owner\_aws\_access\_key\_id](#input\_network\_owner\_aws\_access\_key\_id) | The access key provides access to AWS services and is associated with the shared-vpc AWS account. | `string` | `""` | no |
| <a name="input_network_owner_aws_profile"></a> [network\_owner\_aws\_profile](#input\_network\_owner\_aws\_profile) | The name of the AWS profile configured in the AWS credentials file (typically located at ~/.aws/credentials). This profile contains the access key, secret key, and optional session token associated with the shared-vpc AWS account. | `string` | `""` | no |
| <a name="input_network_owner_aws_secret_access_key"></a> [network\_owner\_aws\_secret\_access\_key](#input\_network\_owner\_aws\_secret\_access\_key) | The secret key paired with the access key. Together, they provide the necessary credentials for Terraform to authenticate with the shared-vpc AWS account and manage resources securely. | `string` | `""` | no |
| <a name="input_network_owner_aws_shared_credentials_files"></a> [network\_owner\_aws\_shared\_credentials\_files](#input\_network\_owner\_aws\_shared\_credentials\_files) | List of files path to the AWS shared credentials file. This file typically contains AWS access keys and secret keys and is used when authenticating with AWS using profiles (default file located at ~/.aws/credentials). | `list(string)` | `null` | no |
| <a name="input_openshift_version"></a> [openshift\_version](#input\_openshift\_version) | The required version of Red Hat OpenShift for the cluster, for example '4.1.0'. If version is greater than the currently running version, an upgrade will be scheduled. | `string` | `"4.14.9"` | no |
| <a name="input_version_channel_group"></a> [version\_channel\_group](#input\_version\_channel\_group) | Desired channel group of the version [stable, candidate, fast, nightly]. | `string` | `"stable"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_role_prefix"></a> [account\_role\_prefix](#output\_account\_role\_prefix) | The prefix used for all generated AWS resources. |
| <a name="output_account_roles_arn"></a> [account\_roles\_arn](#output\_account\_roles\_arn) | A map of Amazon Resource Names (ARNs) associated with the AWS IAM roles created. The key in the map represents the name of an AWS IAM role, while the corresponding value represents the associated Amazon Resource Name (ARN) of that role. |
| <a name="output_api_url"></a> [api\_url](#output\_api\_url) | URL of the API server. |
| <a name="output_cluster_admin_password"></a> [cluster\_admin\_password](#output\_cluster\_admin\_password) | The password of the admin user. |
| <a name="output_cluster_admin_username"></a> [cluster\_admin\_username](#output\_cluster\_admin\_username) | The username of the admin user. |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | Unique identifier of the cluster. |
| <a name="output_console_url"></a> [console\_url](#output\_console\_url) | URL of the console. |
| <a name="output_current_version"></a> [current\_version](#output\_current\_version) | The currently running version of OpenShift on the cluster, for example '4.11.0'. |
| <a name="output_domain"></a> [domain](#output\_domain) | DNS domain of cluster. |
| <a name="output_oidc_config_id"></a> [oidc\_config\_id](#output\_oidc\_config\_id) | The unique identifier associated with users authenticated through OpenID Connect (OIDC) generated by this OIDC config. |
| <a name="output_oidc_endpoint_url"></a> [oidc\_endpoint\_url](#output\_oidc\_endpoint\_url) | Registered OIDC configuration issuer URL, generated by this OIDC config. |
| <a name="output_operator_role_prefix"></a> [operator\_role\_prefix](#output\_operator\_role\_prefix) | Prefix used for generated AWS operator policies. |
| <a name="output_operator_roles_arn"></a> [operator\_roles\_arn](#output\_operator\_roles\_arn) | List of Amazon Resource Names (ARNs) for all operator roles created. |
| <a name="output_password"></a> [password](#output\_password) | n/a |
| <a name="output_path"></a> [path](#output\_path) | The arn path for the account/operator roles as well as their policies. |
| <a name="output_state"></a> [state](#output\_state) | The state of the cluster. |
<!-- END_AUTOMATED_TF_DOCS_BLOCK -->
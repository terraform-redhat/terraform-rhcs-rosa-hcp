locals {
  account_role_prefix          = "${var.cluster_name}-acc"
  operator_role_prefix         = "${var.cluster_name}-op"
  shared_resources_name_prefix = var.cluster_name
  shared_route53_role_name     = substr("${local.shared_resources_name_prefix}-shared-route53-role", 0, 64)
  shared_vpce_role_name        = substr("${local.shared_resources_name_prefix}-shared-vpce-role", 0, 64)
  shared_vpc_roles_arns = {
    "route53" : "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.shared_vpc.account_id}:role/${local.shared_route53_role_name}",
    "vpce" : "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.shared_vpc.account_id}:role/${local.shared_vpce_role_name}"
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

##############################################################
# Account roles includes IAM roles and IAM policies
##############################################################
module "account_iam_resources" {
  source = "../../modules/account-iam-resources"

  account_role_prefix        = local.account_role_prefix
  create_shared_vpc_policies = true
  shared_vpc_roles           = local.shared_vpc_roles_arns
}

############################
# OIDC provider
############################
module "oidc_config_and_provider" {
  source = "../../modules/oidc-config-and-provider"

  managed = true
}

############################
# operator roles
############################
module "operator_roles" {
  source = "../../modules/operator-roles"

  operator_role_prefix       = local.operator_role_prefix
  path                       = module.account_iam_resources.path
  oidc_endpoint_url          = module.oidc_config_and_provider.oidc_endpoint_url
  create_shared_vpc_policies = false
  shared_vpc_roles           = local.shared_vpc_roles_arns
}

resource "rhcs_dns_domain" "dns_domain" {
  //cluster_arch = "hcp"
}

############################
# shared-vpc-resources
############################
provider "aws" {
  alias = "shared-vpc"

  access_key               = var.shared_vpc_aws_access_key_id
  secret_key               = var.shared_vpc_aws_secret_access_key
  region                   = data.aws_region.current.name
  profile                  = var.shared_vpc_aws_profile
  shared_credentials_files = var.shared_vpc_aws_shared_credentials_files
}

data "aws_caller_identity" "shared_vpc" {
  provider = aws.shared-vpc
}

module "vpc" {
  source = "../../modules/vpc"

  providers = {
    aws = aws.shared-vpc
  }

  name_prefix              = local.shared_resources_name_prefix
  availability_zones_count = 1
}

module "shared-vpc-resources" {
  source = "../../modules/shared-vpc-resources"

  providers = {
    aws = aws.shared-vpc
  }

  cluster_name                            = var.cluster_name
  account_roles_prefix                    = local.account_role_prefix
  operator_roles_prefix                   = local.operator_role_prefix
  ingress_private_hosted_zone_base_domain = rhcs_dns_domain.dns_domain.id
  name_prefix                             = local.shared_resources_name_prefix
  target_aws_account                      = data.aws_caller_identity.current.account_id
  subnets                                 = concat(module.vpc.private_subnets, module.vpc.public_subnets)
  vpc_id                                  = module.vpc.vpc_id
}

############################
# ROSA STS cluster
############################
# module "rosa_cluster_hcp" {
#   source = "../../modules/rosa-cluster-hcp"

#   cluster_name                 = var.cluster_name
#   operator_role_prefix         = module.operator_roles.operator_role_prefix
#   account_role_prefix          = module.account_iam_resources.account_role_prefix
#   openshift_version            = var.openshift_version
#   oidc_config_id               = module.oidc_config_and_provider.oidc_config_id
#   aws_subnet_ids               = module.shared-vpc-policy-and-hosted-zone.shared_subnets
#   multi_az                     = length(module.vpc.availability_zones) > 1
#   replicas                     = 3
#   admin_credentials_username   = "kubeadmin"
#   admin_credentials_password   = random_password.password.result
#   base_dns_domain              = rhcs_dns_domain.dns_domain.id
#   private_hosted_zone_id       = module.shared-vpc-policy-and-hosted-zone.hosted_zone_id
#   private_hosted_zone_role_arn = module.shared-vpc-policy-and-hosted-zone.shared_role
# }

# resource "random_password" "password" {
#   length  = 14
#   special = true
# }

locals {
  shared_vpc_aws_credentials_provided = length(var.shared_vpc_aws_access_key_id) > 0 && length(var.shared_vpc_aws_secret_access_key) > 0
  shared_vpc_aws_profile_provided     = length(var.shared_vpc_aws_profile) > 0
}

resource "null_resource" "validations" {
  lifecycle {
    precondition {
      condition     = (local.shared_vpc_aws_credentials_provided == false && local.shared_vpc_aws_profile_provided == false) == false
      error_message = "AWS credentials for the shared-vpc account must be provided. This can provided with \"var.shared_vpc_aws_access_key_id\" and \"var.shared_vpc_aws_secret_access_key\" or with existing profile \"var.shared_vpc_aws_profile\""
    }
  }
}

data "aws_partition" "current" {}

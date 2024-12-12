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

  account_role_prefix                   = local.account_role_prefix
  create_shared_vpc_policies            = true
  shared_vpc_roles                      = local.shared_vpc_roles_arns
  attach_worker_role_zero_egress_policy = true
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
  is_zero_egress           = true
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
  subnets                                 = concat(module.vpc.private_subnets)
  vpc_id                                  = module.vpc.vpc_id
}

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
  private                    = true
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
  properties = {
    "zero_egress" : "true"
  }
}

resource "random_password" "password" {
  length      = 14
  special     = true
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

############################
# Bastion instance for connection to the cluster
############################

data "aws_ami" "rhel9" {
  most_recent = true

  filter {
    name   = "platform-details"
    values = ["Red Hat Enterprise Linux"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "manifest-location"
    values = ["amazon/RHEL-9.*_HVM-*-x86_64-*-Hourly2-GP2"]
  }

  owners = ["309956199498"] # Amazon's "Official Red Hat" account
}
module "bastion_host" {
  providers = {
    aws = aws.network-owner
  }
  source     = "../../modules/bastion-host"
  prefix     = var.cluster_name
  vpc_id     = module.vpc.vpc_id
  subnet_ids = [module.vpc.public_subnets[0]]
  ami_id         = aws_ami.rhel9.id
  user_data_file = file("../../assets/bastion-host-user-data.yaml")
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

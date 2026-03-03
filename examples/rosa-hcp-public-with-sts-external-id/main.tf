locals {
  account_role_prefix  = "${var.cluster_name}-account"
  operator_role_prefix = "${var.cluster_name}-operator"
}

module "hcp" {
  source = "../../"

  cluster_name           = var.cluster_name
  openshift_version      = var.openshift_version
  machine_cidr           = module.vpc.cidr_block
  aws_subnet_ids         = concat(module.vpc.public_subnets, module.vpc.private_subnets)
  aws_availability_zones = module.vpc.availability_zones
  replicas               = length(module.vpc.availability_zones)

  // STS configuration
  create_account_roles     = true
  account_role_prefix      = local.account_role_prefix
  trust_policy_external_id = var.trust_policy_external_id
  create_oidc              = true
  create_operator_roles    = true
  operator_role_prefix     = local.operator_role_prefix
}

############################
# VPC
############################
module "vpc" {
  source = "../../modules/vpc"

  name_prefix              = var.cluster_name
  availability_zones_count = 3
}

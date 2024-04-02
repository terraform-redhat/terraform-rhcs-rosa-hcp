locals {
  account_role_prefix  = "${var.cluster_name}-account"
  operator_role_prefix = "${var.cluster_name}-operator"
}

############################
# Cluster
############################
module "hcp" {
  source = "../../"

  cluster_name         = var.cluster_name
  openshift_version    = var.openshift_version
  machine_cidr         = module.vpc.cidr_block
  account_role_prefix  = module.account_iam_resources.account_role_prefix
  operator_role_prefix = module.operator_roles.operator_role_prefix
  oidc_config_id       = module.oidc_config_and_provider.oidc_config_id # replace with variable once split out properly
  aws_subnet_ids         = module.vpc.private_subnets
  aws_availability_zones = module.vpc.availability_zones
  path                   = module.account_iam_resources.path
  replicas               = length(module.vpc.availability_zones)
  private = true
}

############################
# HTPASSWD IDP
############################
module "htpasswd_idp" {
  source = "../../modules/idp"

  cluster_id         = module.hcp.cluster_id
  name               = "htpasswd-idp"
  idp_type           = "htpasswd"
  htpasswd_idp_users = [{ username = "test-user", password = random_password.password.result }]
}

resource "random_password" "password" {
  length  = 14
  special = true
}

############################
# VPC
############################
module "vpc" {
  source = "../../modules/vpc"

  name_prefix  = var.cluster_name
  availability_zones_count = 3
}

############################
# IAM Account roles
############################
module "account_iam_resources" {
  source = "../../modules/account-iam-resources"

  account_role_prefix = local.account_role_prefix
}

############################
# IAM Operator Roles
############################
module "operator_roles" {
  source = "../../modules/operator-roles"

  operator_role_prefix = local.operator_role_prefix
  path                 = module.account_iam_resources.path
  oidc_endpoint_url    = module.oidc_config_and_provider.oidc_endpoint_url
}

############################
# OIDC Config and provider
############################
module "oidc_config_and_provider" {
  source = "../../modules/oidc-config-and-provider"

  managed            = true
}


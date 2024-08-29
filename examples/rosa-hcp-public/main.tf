locals {
  account_role_prefix  = "${var.cluster_name}-account"
  operator_role_prefix = "${var.cluster_name}-operator"
}

############################
# Cluster
############################
module "hcp" {
  source = "terraform-redhat/rosa-hcp/rhcs"
  version = "1.6.3-prerelease.1"

  cluster_name           = var.cluster_name
  openshift_version      = var.openshift_version
  machine_cidr           = module.vpc.cidr_block
  aws_subnet_ids         = concat(module.vpc.public_subnets, module.vpc.private_subnets)
  aws_availability_zones = module.vpc.availability_zones
  replicas               = length(module.vpc.availability_zones)
  create_admin_user      = true

  // STS configuration
  create_account_roles  = true
  account_role_prefix   = local.account_role_prefix
  create_oidc           = true
  create_operator_roles = true
  operator_role_prefix  = local.operator_role_prefix
}

module "mp" {
  source = "terraform-redhat/rosa-hcp/rhcs//modules/machine-pool"
  version = "1.6.3-prerelease.1"

  cluster_id = module.hcp.cluster_id

  autoscaling = {
    enabled = false
    min_replicas = null
    max_replicas = null
  }
  replicas = 2
  auto_repair = true
  name = "mp2"
  openshift_version = var.openshift_version
  subnet_id = module.vpc.private_subnets[0]
  aws_node_pool = {
    instance_type = "m5.xlarge"
    tags = {}
  }
}

############################
# HTPASSWD IDP
############################
module "htpasswd_idp" {
  source = "terraform-redhat/rosa-hcp/rhcs//modules/idp"
  version = "1.6.3-prerelease.1"

  cluster_id         = module.hcp.cluster_id
  name               = "htpasswd-idp"
  idp_type           = "htpasswd"
  htpasswd_idp_users = [{ username = "test-user", password = random_password.password.result }]
}

resource "random_password" "password" {
  length  = 14
  special = true
  min_lower = 1
  min_numeric = 1
  min_special = 1
  min_upper = 1
}

############################
# VPC
############################
module "vpc" {
  source = "terraform-redhat/rosa-hcp/rhcs//modules/vpc"
  version = "1.6.3-prerelease.1"

  name_prefix              = var.cluster_name
  availability_zones_count = 3
}

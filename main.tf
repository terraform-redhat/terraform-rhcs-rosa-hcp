data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  account_role_prefix  = coalesce(var.account_role_prefix, "${var.cluster_name}-account")
  operator_role_prefix = coalesce(var.operator_role_prefix, "${var.cluster_name}-operator")
  sts_roles = {
    installer_role_arn    = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.account_role_prefix}-HCP-ROSA-Installer-Role",
    support_role_arn      = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.account_role_prefix}-HCP-ROSA-Support-Role",
    worker_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.account_role_prefix}-HCP-ROSA-Worker-Role"
  }
}

##############################################################
# Account roles includes IAM roles and IAM policies
##############################################################

module "account_iam_resources" {
  source = "./modules/account-iam-resources"
  count  = var.create_account_roles ? 1 : 0

  account_role_prefix = local.account_role_prefix
  openshift_version   = var.openshift_version
}

############################
# unmanaged OIDC config
############################
module "unmanaged_oidc_config" {
  source = "./modules/unmanaged-oidc-config"
  count  = var.create_oidc && var.oidc == "unmanaged" ? 1 : 0
}

############################
# OIDC provider
############################
module "oidc_provider" {
  source = "./modules/oidc-provider"
  count  = var.create_oidc ? 1 : 0

  managed            = var.oidc == "managed" ? true : false
  installer_role_arn = var.oidc == "managed" ? null : local.sts_roles.installer_role_arn
  secret_arn         = var.oidc == "managed" ? null : module.unmanaged_oidc_config[0].secret_arn
  issuer_url         = var.oidc == "managed" ? null : module.unmanaged_oidc_config[0].issuer_url
}

############################
# operator roles
############################
module "operator_roles" {
  source = "./modules/operator-roles"
  count  = var.create_operator_roles ? 1 : 0

  operator_role_prefix = local.operator_role_prefix
  account_role_prefix  = local.account_role_prefix
  path                 = var.create_account_roles ? module.account_iam_resources[0].path : var.account_role_path
  oidc_endpoint_url    = var.create_oidc ? module.oidc_provider[0].oidc_endpoint_url : var.oidc_endpoint_url
}

resource "null_resource" "validations" {
  lifecycle {
    precondition {
      condition     = (var.private == true && (length(var.vpc_public_subnets_ids) > 0)) == false
      error_message = "ERROR: Public subnet IDs shouldn't be provided for private cluster"
    }
  }
}

############################
# ROSA STS cluster
############################
module "rosa_cluster_hcp" {
  source = "./modules/rosa-cluster-hcp"

  cluster_name          = var.cluster_name
  operator_role_prefix  = local.operator_role_prefix
  openshift_version     = var.openshift_version
  replicas              = var.replicas
  installer_role_arn    = var.create_account_roles ? module.account_iam_resources[0].account_roles_arn["Installer"] : local.sts_roles.installer_role_arn
  support_role_arn      = var.create_account_roles ? module.account_iam_resources[0].account_roles_arn["Support"] : local.sts_roles.support_role_arn
  worker_role_arn       = var.create_account_roles ? module.account_iam_resources[0].account_roles_arn["Worker"] : local.sts_roles.worker_role_arn
  oidc_config_id        = var.create_oidc ? module.oidc_provider[0].oidc_config_id : var.oidc_config_id
  aws_subnet_ids        = concat(var.vpc_private_subnets_ids, var.vpc_public_subnets_ids)
  availability_zones    = var.availability_zones
  machine_cidr          = var.machine_cidr
  autoscaling_enabled   = var.autoscaling_enabled
  min_replicas          = var.min_replicas
  max_replicas          = var.max_replicas
}

resource "random_password" "password" {
  length  = 14
  special = true
}

############################
# machine pools
############################

module "rhcs_machine_pool" {
  source   = "./modules/machine-pool"
  for_each = var.machine_pools

  cluster_id          = module.rosa_cluster_hcp.cluster_id
  name                = each.value.name
  machine_type        = each.value.machine_type
  autoscaling_enabled = try(each.value.autoscaling_enabled, false)
  use_spot_instances  = try(each.value.use_spot_instances, false)
  max_replicas        = try(each.value.max_replicas, null)
  max_spot_price      = try(each.value.max_spot_price, null)
  min_replicas        = try(each.value.min_replicas, null)
  replicas            = try(each.value.replicas, null)
  taints              = try(each.value.taints, null)
  labels              = try(each.value.labels, null)
}

############################
# idp
############################

module "rhcs_identity_provider" {
  source   = "./modules/idp"
  for_each = var.idp

  cluster_id     = module.rosa_cluster_hcp.cluster_id
  name           = each.value.name
  github         = try(each.value.github, null)
  gitlab         = try(each.value.gitlab, null)
  google         = try(each.value.google, null)
  htpasswd       = try(each.value.htpasswd, null)
  ldap           = try(each.value.ldap, null)
  openid         = try(each.value.openid, null)
  mapping_method = try(each.value.mapping_method, "claim")
}



locals {
  path                 = coalesce(var.path, "/")
  account_role_prefix  = coalesce(var.account_role_prefix, "${var.cluster_name}-account")
  operator_role_prefix = coalesce(var.operator_role_prefix, "${var.cluster_name}-operator")
  sts_roles = {
    installer_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role${local.path}${local.account_role_prefix}-HCP-ROSA-Installer-Role",
    support_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role${local.path}${local.account_role_prefix}-HCP-ROSA-Support-Role",
    worker_role_arn    = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role${local.path}${local.account_role_prefix}-HCP-ROSA-Worker-Role"
  }
}

##############################################################
# Account roles includes IAM roles and IAM policies
##############################################################

module "account_iam_resources" {
  source = "./modules/account-iam-resources"
  count  = var.create_account_roles ? 1 : 0

  account_role_prefix  = local.account_role_prefix
  path                 = local.path
  permissions_boundary = var.permissions_boundary
  tags                 = var.tags
}

############################
# OIDC config and provider
############################
module "oidc_config_and_provider" {
  source = "./modules/oidc-config-and-provider"
  count  = var.create_oidc ? 1 : 0

  managed = var.managed_oidc
  installer_role_arn = var.managed_oidc ? (
    null
    ) : (
    var.create_account_roles ? (
      module.account_iam_resources[0].account_roles_arn["HCP-ROSA-Installer"]
      ) : (
      local.sts_roles.installer_role_arn
    )
  )
  tags = var.tags
}

############################
# operator roles
############################
module "operator_roles" {
  source = "./modules/operator-roles"
  count  = var.create_operator_roles ? 1 : 0

  operator_role_prefix = local.operator_role_prefix
  path                 = var.create_account_roles ? module.account_iam_resources[0].path : local.path
  oidc_endpoint_url    = var.create_oidc ? module.oidc_config_and_provider[0].oidc_endpoint_url : var.oidc_endpoint_url
  tags                 = var.tags
  permissions_boundary = var.permissions_boundary
}

############################
# ROSA STS cluster
############################
module "rosa_cluster_hcp" {
  source = "./modules/rosa-cluster-hcp"

  cluster_name         = var.cluster_name
  operator_role_prefix = var.create_operator_roles ? module.operator_roles[0].operator_role_prefix : local.operator_role_prefix
  openshift_version    = var.openshift_version
  installer_role_arn   = var.create_account_roles ? module.account_iam_resources[0].account_roles_arn["HCP-ROSA-Installer"] : local.sts_roles.installer_role_arn
  support_role_arn     = var.create_account_roles ? module.account_iam_resources[0].account_roles_arn["HCP-ROSA-Support"] : local.sts_roles.support_role_arn
  worker_role_arn      = var.create_account_roles ? module.account_iam_resources[0].account_roles_arn["HCP-ROSA-Worker"] : local.sts_roles.worker_role_arn
  oidc_config_id       = var.create_oidc ? module.oidc_config_and_provider[0].oidc_config_id : var.oidc_config_id
  aws_subnet_ids       = var.aws_subnet_ids
  machine_cidr         = var.machine_cidr
  service_cidr         = var.service_cidr
  pod_cidr             = var.pod_cidr
  host_prefix          = var.host_prefix
  private              = var.private
  tags                 = var.tags
  properties           = var.properties
  etcd_encryption      = var.etcd_encryption
  etcd_kms_key_arn     = var.etcd_kms_key_arn
  kms_key_arn          = var.kms_key_arn

  ########
  # Flags
  ########
  wait_for_create_complete     = var.wait_for_create_complete
  disable_waiting_in_destroy   = var.disable_waiting_in_destroy
  destroy_timeout              = var.destroy_timeout
  upgrade_acknowledgements_for = var.upgrade_acknowledgements_for

  #######################
  # Default Machine Pool
  #######################

  replicas               = var.replicas
  compute_machine_type   = var.compute_machine_type
  aws_availability_zones = var.aws_availability_zones

  ########
  # Proxy 
  ########
  http_proxy              = var.http_proxy
  https_proxy             = var.https_proxy
  no_proxy                = var.no_proxy
  additional_trust_bundle = var.additional_trust_bundle

  #############
  # Autoscaler 
  #############
  cluster_autoscaler_enabled         = var.cluster_autoscaler_enabled
  autoscaler_max_pod_grace_period    = var.autoscaler_max_pod_grace_period
  autoscaler_pod_priority_threshold  = var.autoscaler_pod_priority_threshold
  autoscaler_max_node_provision_time = var.autoscaler_max_node_provision_time
  autoscaler_max_nodes_total         = var.autoscaler_max_nodes_total

  ##################
  # default_ingress 
  ##################
  default_ingress_listening_method = var.default_ingress_listening_method != "" ? (
    var.default_ingress_listening_method) : (
    var.private ? "internal" : "external"
  )
}

resource "null_resource" "validations" {
  lifecycle {
    precondition {
      condition     = (var.create_operator_roles == true && var.create_oidc != true && var.oidc_endpoint_url == null) == false
      error_message = "\"oidc_endpoint_url\" mustn't be empty when oidc is pre-created (create_oidc != true)."
    }
    precondition {
      condition     = (var.create_oidc != true && var.oidc_config_id == null) == false
      error_message = "\"oidc_config_id\" mustn't be empty when oidc is pre-created (create_oidc != true)."
    }
  }
}

data "aws_caller_identity" "current" {}

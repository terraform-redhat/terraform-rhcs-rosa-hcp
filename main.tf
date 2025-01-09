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
  installer_role_arn = var.managed_oidc ? (null) : (
    var.create_account_roles ? (module.account_iam_resources[0].account_roles_arn["HCP-ROSA-Installer"]) : (
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
  path                 = local.path
  oidc_endpoint_url    = var.create_oidc ? module.oidc_config_and_provider[0].oidc_endpoint_url : var.oidc_endpoint_url
  tags                 = var.tags
  permissions_boundary = var.permissions_boundary
}

############################
# ROSA STS cluster
############################
module "rosa_cluster_hcp" {
  source = "./modules/rosa-cluster-hcp"

  cluster_name             = var.cluster_name
  operator_role_prefix     = var.create_operator_roles ? module.operator_roles[0].operator_role_prefix : local.operator_role_prefix
  openshift_version        = var.openshift_version
  installer_role_arn       = var.create_account_roles ? module.account_iam_resources[0].account_roles_arn["HCP-ROSA-Installer"] : local.sts_roles.installer_role_arn
  support_role_arn         = var.create_account_roles ? module.account_iam_resources[0].account_roles_arn["HCP-ROSA-Support"] : local.sts_roles.support_role_arn
  worker_role_arn          = var.create_account_roles ? module.account_iam_resources[0].account_roles_arn["HCP-ROSA-Worker"] : local.sts_roles.worker_role_arn
  oidc_config_id           = var.create_oidc ? module.oidc_config_and_provider[0].oidc_config_id : var.oidc_config_id
  aws_subnet_ids           = var.aws_subnet_ids
  machine_cidr             = var.machine_cidr
  service_cidr             = var.service_cidr
  pod_cidr                 = var.pod_cidr
  host_prefix              = var.host_prefix
  private                  = var.private
  tags                     = var.tags
  properties               = var.properties
  etcd_encryption          = var.etcd_encryption
  etcd_kms_key_arn         = var.etcd_kms_key_arn
  kms_key_arn              = var.kms_key_arn
  aws_billing_account_id   = var.aws_billing_account_id
  ec2_metadata_http_tokens = var.ec2_metadata_http_tokens

  ########
  # Cluster Admin User
  ########  
  create_admin_user          = var.create_admin_user
  admin_credentials_username = var.admin_credentials_username
  admin_credentials_password = var.admin_credentials_password

  ########
  # Flags
  ########
  wait_for_create_complete            = var.wait_for_create_complete
  wait_for_std_compute_nodes_complete = var.wait_for_std_compute_nodes_complete
  disable_waiting_in_destroy          = var.disable_waiting_in_destroy
  destroy_timeout                     = var.destroy_timeout
  upgrade_acknowledgements_for        = var.upgrade_acknowledgements_for

  #######################
  # Default Machine Pool
  #######################

  replicas                                  = var.replicas
  compute_machine_type                      = var.compute_machine_type
  aws_availability_zones                    = var.aws_availability_zones
  aws_additional_compute_security_group_ids = var.aws_additional_compute_security_group_ids

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

######################################
# Multiple Machine Pools Generic block
######################################

module "rhcs_hcp_machine_pool" {
  source   = "./modules/machine-pool"
  for_each = var.machine_pools

  cluster_id                   = module.rosa_cluster_hcp.cluster_id
  name                         = each.value.name
  auto_repair                  = try(each.value.auto_repair, null)
  autoscaling                  = try(each.value.autoscaling, null)
  aws_node_pool                = each.value.aws_node_pool
  openshift_version            = try(each.value.openshift_version, null)
  tuning_configs               = try(each.value.tuning_configs, null)
  upgrade_acknowledgements_for = try(each.value.upgrade_acknowledgements_for, null)
  replicas                     = try(each.value.replicas, null)
  taints                       = try(each.value.taints, null)
  labels                       = try(each.value.labels, null)
  subnet_id                    = each.value.subnet_id
  kubelet_configs              = try(each.value.kubelet_configs, null)
  ignore_deletion_error        = try(each.value.ignore_deletion_error, var.ignore_machine_pools_deletion_error)
}

###########################################
# Multiple Identity Providers Generic block
###########################################

module "rhcs_identity_provider" {
  source   = "./modules/idp"
  for_each = var.identity_providers

  cluster_id                            = module.rosa_cluster_hcp.cluster_id
  name                                  = each.value.name
  idp_type                              = each.value.idp_type
  mapping_method                        = try(each.value.mapping_method, null)
  github_idp_client_id                  = try(each.value.github_idp_client_id, null)
  github_idp_client_secret              = try(each.value.github_idp_client_secret, null)
  github_idp_ca                         = try(each.value.github_idp_ca, null)
  github_idp_hostname                   = try(each.value.github_idp_hostname, null)
  github_idp_organizations              = try(jsondecode(each.value.github_idp_organizations), null)
  github_idp_teams                      = try(jsondecode(each.value.github_idp_teams), null)
  gitlab_idp_client_id                  = try(each.value.gitlab_idp_client_id, null)
  gitlab_idp_client_secret              = try(each.value.gitlab_idp_client_secret, null)
  gitlab_idp_url                        = try(each.value.gitlab_idp_url, null)
  gitlab_idp_ca                         = try(each.value.gitlab_idp_ca, null)
  google_idp_client_id                  = try(each.value.google_idp_client_id, null)
  google_idp_client_secret              = try(each.value.google_idp_client_secret, null)
  google_idp_hosted_domain              = try(each.value.google_idp_hosted_domain, null)
  htpasswd_idp_users                    = try(jsondecode(each.value.htpasswd_idp_users), null)
  ldap_idp_bind_dn                      = try(each.value.ldap_idp_bind_dn, null)
  ldap_idp_bind_password                = try(each.value.ldap_idp_bind_password, null)
  ldap_idp_ca                           = try(each.value.ldap_idp_ca, null)
  ldap_idp_insecure                     = try(each.value.ldap_idp_insecure, null)
  ldap_idp_url                          = try(each.value.ldap_idp_url, null)
  ldap_idp_emails                       = try(jsondecode(each.value.ldap_idp_emails), null)
  ldap_idp_ids                          = try(jsondecode(each.value.ldap_idp_ids), null)
  ldap_idp_names                        = try(jsondecode(each.value.ldap_idp_names), null)
  ldap_idp_preferred_usernames          = try(jsondecode(each.value.ldap_idp_preferred_usernames), null)
  openid_idp_ca                         = try(each.value.openid_idp_ca, null)
  openid_idp_claims_email               = try(jsondecode(each.value.openid_idp_claims_email), null)
  openid_idp_claims_groups              = try(jsondecode(each.value.openid_idp_claims_groups), null)
  openid_idp_claims_name                = try(jsondecode(each.value.openid_idp_claims_name), null)
  openid_idp_claims_preferred_username  = try(jsondecode(each.value.openid_idp_claims_preferred_username), null)
  openid_idp_client_id                  = try(each.value.openid_idp_client_id, null)
  openid_idp_client_secret              = try(each.value.openid_idp_client_secret, null)
  openid_idp_extra_scopes               = try(jsondecode(each.value.openid_idp_extra_scopes), null)
  openid_idp_extra_authorize_parameters = try(jsondecode(each.value.openid_idp_extra_authorize_parameters), null)
  openid_idp_issuer                     = try(each.value.openid_idp_issuer, null)
}

######################################
# Multiple Kubelet Configs block
######################################
module "rhcs_hcp_kubelet_configs" {
  source   = "./modules/kubelet-configs"
  for_each = var.kubelet_configs

  cluster_id     = module.rosa_cluster_hcp.cluster_id
  name           = each.value.name
  pod_pids_limit = each.value.pod_pids_limit
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

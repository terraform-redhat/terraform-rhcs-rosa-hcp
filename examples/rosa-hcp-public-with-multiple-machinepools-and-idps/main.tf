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
  create_account_roles  = true
  account_role_prefix   = local.account_role_prefix
  create_oidc           = true
  create_operator_roles = true
  operator_role_prefix  = local.operator_role_prefix
  kubelet_configs = {
    config1 = {
      name = "config1"
      pod_pids_limit = 8192
    },
    config2 = {
      name = "config2"
      pod_pids_limit = 16384
    }
  }
  machine_pools = {
    pool1 = {
      name = "pool1"
      aws_node_pool = {
        instance_type = "r5.xlarge"
        tags = {}
      }
      auto_repair = true
      replicas = 3
      openshift_version = var.openshift_version
      subnet_id = module.vpc.private_subnets[0]
      kubelet_configs = "config1"
    },
    pool2 = {
      name = "pool2"
      aws_node_pool = {
        instance_type = "r5.xlarge"
        tags = {}
      }
      auto_repair = true
      replicas = 3
      openshift_version = var.openshift_version
      subnet_id = module.vpc.private_subnets[1]
      kubelet_configs = "config2"
    },
  }
  identity_providers = {
    gitlab-idp = {
      name                     = "gitlab-idp"
      idp_type                 = "gitlab"
      gitlab_idp_client_id     = random_password.client_id.result     # replace with valid <client-id>
      gitlab_idp_client_secret = random_password.client_secret.result # replace with valid <client-secret>
      gitlab_idp_url           = "https://gitlab.com"
    },
    htpasswd-idp = {
      name               = "htpasswd-idp"
      idp_type           = "htpasswd"
      htpasswd_idp_users = jsonencode([{ username = "test-user", password = random_password.password.result }])
    },
    github-idp = {
      name                     = "github-idp"
      idp_type                 = "github"
      github_idp_client_id     = random_password.client_id.result     # replace with valid <client-id>
      github_idp_client_secret = random_password.client_secret.result # replace with valid <client-secret>
      github_idp_organizations = jsonencode(["example"])
    },
    google-idp = {
      name                     = "google-idp"
      idp_type                 = "google"
      google_idp_client_id     = random_password.client_id.result     # replace with valid <client-id>
      google_idp_client_secret = random_password.client_secret.result # replace with valid <client-secret>
      google_idp_hosted_domain = "example.com"
    },
    ldap-idp = {
      name              = "ldap-idp"
      idp_type          = "ldap"
      ldap_idp_ca       = ""
      ldap_idp_url      = "ldap://ldap.forumsys.com/dc=example,dc=com?uid"
      ldap_idp_insecure = true
    },
    openid-idp = {
      name                                 = "openid-idp"
      idp_type                             = "openid"
      openid_idp_client_id                 = random_password.client_id.result     # replace with valid <client-id>
      openid_idp_client_secret             = random_password.client_secret.result # replace with valid <client-secret>
      openid_idp_ca                        = ""
      openid_idp_issuer                    = "https://example.com"
      openid_idp_claims_email              = jsonencode(["example@email.com"])
      openid_idp_claims_groups             = jsonencode(["example"])
      openid_idp_claims_name               = jsonencode(["example"])
      openid_idp_claims_preferred_username = jsonencode(["example"])
    },
  }
}

resource "random_password" "client_id" {
  length = 16

  numeric     = true
  upper       = false
  lower       = false
  special     = false
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

resource "random_password" "client_secret" {
  length = 39

  numeric     = true
  upper       = true
  lower       = false
  special     = false
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
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
# VPC
############################
module "vpc" {
  source = "../../modules/vpc"

  name_prefix              = var.cluster_name
  availability_zones_count = 3
}


# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

locals {
  account_role_prefix  = "${var.cluster_name}-account"
  operator_role_prefix = "${var.cluster_name}-operator"
}

############################
# Cluster
############################
module "hcp" {
  source = "../../"

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

  // Optional CloudWatch audit log forwarding. Pass the ARN of an EXISTING
  // user-created IAM role whose trust policy federates the cluster OIDC
  // provider for the service account
  // system:serviceaccount:openshift-config-managed:cloudwatch-audit-exporter.
  // This example does not create that role. Leave null to keep forwarding
  // disabled on create; set explicit null to disable forwarding on an
  // already-enabled cluster. Avoid an empty string to disable: with RHCS
  // provider 1.7.10 a day-2 "" change was observed to fail with
  // "Provider produced inconsistent result after apply".
  audit_log_arn = var.audit_log_arn
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

  name_prefix                       = var.cluster_name
  availability_zones_count          = 3
  cleanup_rosa_vpce_security_groups = true
}

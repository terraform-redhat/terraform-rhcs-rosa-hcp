# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

locals {
  account_role_prefix  = "${var.cluster_name}-account"
  operator_role_prefix = "${var.cluster_name}-operator"
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

############################
# Karpenter (AutoNode) IAM role
############################
data "aws_iam_policy_document" "karpenter_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${module.hcp.oidc_endpoint_url}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${module.hcp.oidc_endpoint_url}:sub"
      values   = ["system:serviceaccount:kube-system:karpenter"]
    }
  }
}

resource "aws_iam_role" "karpenter" {
  name               = "${local.operator_role_prefix}-kube-system-karpenter"
  assume_role_policy = data.aws_iam_policy_document.karpenter_trust.json

  tags = {
    red-hat-managed = "true"
  }
}

resource "aws_iam_role_policy_attachment" "karpenter" {
  role       = aws_iam_role.karpenter.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/ROSAKarpenterControllerPolicy"
}

# Read the role back after the policy is attached so cluster creation (and AutoNode
# activation) waits for the attachment. A depends_on on module.hcp would create a
# cycle through the trust policy's module.hcp.oidc_endpoint_url reference.
data "aws_iam_role" "karpenter" {
  name       = aws_iam_role.karpenter.name
  depends_on = [aws_iam_role_policy_attachment.karpenter]
}

############################
# Cluster
############################
module "hcp" {
  source = "../../"

  cluster_name             = var.cluster_name
  openshift_version        = var.openshift_version
  machine_cidr             = module.vpc.cidr_block
  aws_subnet_ids           = concat(module.vpc.public_subnets, module.vpc.private_subnets)
  aws_availability_zones   = module.vpc.availability_zones
  replicas                 = length(module.vpc.availability_zones)
  create_admin_user        = true
  ec2_metadata_http_tokens = "required"

  // STS configuration
  create_account_roles  = true
  account_role_prefix   = local.account_role_prefix
  create_oidc           = true
  create_operator_roles = true
  operator_role_prefix  = local.operator_role_prefix

  // AutoNode (Karpenter). The Karpenter IAM role is created above in this example.
  // Requires OpenShift 4.22 or later.
  auto_node = {
    mode     = "enabled"
    role_arn = data.aws_iam_role.karpenter.arn
  }
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

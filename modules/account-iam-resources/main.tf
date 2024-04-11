locals {
  path = coalesce(var.path, "/")
  account_roles_properties = [
    {
      role_name            = "HCP-ROSA-Installer"
      role_type            = "installer"
      policy_details       = "arn:aws:iam::aws:policy/service-role/ROSAInstallerPolicy"
      principal_type       = "AWS"
      principal_identifier = "arn:aws:iam::${data.rhcs_info.current.ocm_aws_account_id}:role/RH-Managed-OpenShift-Installer"
    },
    {
      role_name            = "HCP-ROSA-Support"
      role_type            = "support"
      policy_details       = "arn:aws:iam::aws:policy/service-role/ROSASRESupportPolicy"
      principal_type       = "AWS"
      principal_identifier = "arn:aws:iam::${data.rhcs_info.current.ocm_aws_account_id}:role/RH-Technical-Support-Access"
    },
    {
      role_name            = "HCP-ROSA-Worker"
      role_type            = "instance_worker"
      policy_details       = "arn:aws:iam::aws:policy/service-role/ROSAWorkerInstancePolicy"
      principal_type       = "Service"
      principal_identifier = "ec2.amazonaws.com"
    },
  ]
  account_roles_count = length(local.account_roles_properties)
  account_role_prefix_valid = var.account_role_prefix != null ? (
    var.account_role_prefix
    ) : (
    "account-role-${random_string.default_random[0].result}"
  )
}

data "aws_iam_policy_document" "custom_trust_policy" {
  count = local.account_roles_count

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = local.account_roles_properties[count.index].principal_type
      identifiers = [local.account_roles_properties[count.index].principal_identifier]
    }
  }
}

resource "aws_iam_role" "account_role" {
  count                = local.account_roles_count
  name                 = substr("${local.account_role_prefix_valid}-${local.account_roles_properties[count.index].role_name}-Role", 0, 64)
  permissions_boundary = var.permissions_boundary
  path                 = local.path
  assume_role_policy   = data.aws_iam_policy_document.custom_trust_policy[count.index].json

  tags = merge(var.tags, {
    red-hat-managed       = true
    rosa_hcp_policies     = true
    rosa_managed_policies = true
    rosa_role_prefix      = local.account_role_prefix_valid
    rosa_role_type        = local.account_roles_properties[count.index].role_type
  })
}

resource "aws_iam_role_policy_attachment" "account_role_policy_attachment" {
  count      = local.account_roles_count
  role       = aws_iam_role.account_role[count.index].name
  policy_arn = local.account_roles_properties[count.index].policy_details
}

resource "random_string" "default_random" {
  count = var.account_role_prefix != null ? 0 : 1

  length  = 4
  special = false
  upper   = false
}

data "rhcs_info" "current" {}

resource "time_sleep" "account_iam_resources_wait" {
  destroy_duration = "10s"
  create_duration  = "10s"
  triggers = {
    account_iam_role_name = jsonencode([for value in aws_iam_role.account_role : value.name])
    account_roles_arn     = jsonencode({ for idx, value in aws_iam_role.account_role : local.account_roles_properties[idx].role_name => value.arn })
    account_role_prefix   = local.account_role_prefix_valid
    path                  = var.path
  }
}

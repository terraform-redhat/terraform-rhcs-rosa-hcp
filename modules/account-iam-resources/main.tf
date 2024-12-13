data "rhcs_hcp_policies" "all_policies" {}
data "aws_partition" "current" {}
data "rhcs_info" "current" {}
locals {
  path = coalesce(var.path, "/")
  account_roles_properties = {
    "installer" = {
      role_name            = "HCP-ROSA-Installer"
      role_type            = "installer"
      policy_details       = ["arn:aws:iam::aws:policy/service-role/ROSAInstallerPolicy"]
      principal_type       = "AWS"
      principal_identifier = "arn:${data.aws_partition.current.partition}:iam::${data.rhcs_info.current.ocm_aws_account_id}:role/RH-Managed-OpenShift-Installer"
    },
    "support" = {
      role_name      = "HCP-ROSA-Support"
      role_type      = "support"
      policy_details = ["arn:aws:iam::aws:policy/service-role/ROSASRESupportPolicy"]
      principal_type = "AWS"
      // This is a SRE RH Support role which is used to assume this support role
      principal_identifier = data.rhcs_hcp_policies.all_policies.account_role_policies["sts_support_rh_sre_role"]
    },
    "instance_worker" = {
      role_name            = "HCP-ROSA-Worker"
      role_type            = "instance_worker"
      policy_details       = concat(["arn:aws:iam::aws:policy/service-role/ROSAWorkerInstancePolicy"], var.attach_worker_role_zero_egress_policy ? ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"] : [])
      principal_type       = "Service"
      principal_identifier = "ec2.amazonaws.com"
    },
  }
  account_roles_count = length(local.account_roles_properties)
  account_role_prefix_valid = (var.account_role_prefix != null && var.account_role_prefix != "") ? (
    var.account_role_prefix
    ) : (
    "account-role-${random_string.default_random[0].result}"
  )
}

data "aws_iam_policy_document" "custom_trust_policy" {
  for_each = local.account_roles_properties

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = each.value.principal_type
      identifiers = [each.value.principal_identifier]
    }
  }
}

resource "aws_iam_role" "account_role" {
  for_each             = local.account_roles_properties
  name                 = substr("${local.account_role_prefix_valid}-${each.value.role_name}-Role", 0, 64)
  permissions_boundary = var.permissions_boundary
  path                 = local.path
  assume_role_policy   = data.aws_iam_policy_document.custom_trust_policy[each.key].json

  tags = merge(var.tags, {
    red-hat-managed       = true
    rosa_hcp_policies     = true
    rosa_managed_policies = true
    rosa_role_prefix      = local.account_role_prefix_valid
    rosa_role_type        = each.value.role_type
  })
}

locals {
  role_policies = flatten([
    for account_role_property in local.account_roles_properties : [
      for policy in account_role_property.policy_details : {
        name = aws_iam_role.account_role[account_role_property.role_type].name
        arn  = policy
      }
    ]
  ])
}

resource "aws_iam_role_policy_attachment" "account_role_policy_attachment" {
  for_each   = { for role_policy in local.role_policies : "${role_policy.name}-${role_policy.arn}" => role_policy }
  role       = each.value.name
  policy_arn = each.value.arn
}

resource "random_string" "default_random" {
  count = (var.account_role_prefix != null && var.account_role_prefix != "") ? 0 : 1

  length  = 4
  special = false
  upper   = false
}

resource "time_sleep" "account_iam_resources_wait" {
  destroy_duration = "10s"
  create_duration  = "10s"
  triggers = {
    account_iam_role_name = jsonencode([for value in aws_iam_role.account_role : value.name])
    account_roles_arn     = jsonencode({ for idx, value in aws_iam_role.account_role : local.account_roles_properties[idx].role_name => value.arn })
    account_policy_arns   = jsonencode([for value in aws_iam_role_policy_attachment.account_role_policy_attachment : value.policy_arn])
    account_role_prefix   = local.account_role_prefix_valid
    path                  = local.path
  }
}

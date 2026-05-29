# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

locals {
  path = coalesce(var.path, "/")

  role_type               = "OCM"
  role_suffix             = "-${local.role_type}-Role-${data.rhcs_info.current.organization_external_id}"
  max_prefix_length       = 64 - length(local.role_suffix)
  truncated_role_prefix   = local.max_prefix_length > 0 ? substr(var.ocm_role_prefix, 0, local.max_prefix_length) : ""
  role_name               = "${local.truncated_role_prefix}${local.role_suffix}"
  max_policy_name_length  = 128
  standard_policy_enabled = contains(["standard", "admin"], var.profile)
  admin_policy_enabled    = var.profile == "admin"
  no_console_enabled      = var.profile == "no-console"

  ocm_environment = (
    strcontains(data.rhcs_info.current.ocm_api, "api.stage.") ? "staging" :
    (
      strcontains(data.rhcs_info.current.ocm_api, "integration") || strcontains(data.rhcs_info.current.ocm_api, ".int.") ? "integration" : "production"
    )
  )

  base_tags = merge(var.tags, {
    red-hat-managed  = true
    rosa_role_prefix = var.ocm_role_prefix
    rosa_role_type   = local.role_type
    rosa_environment = local.ocm_environment
  })

  role_tags = local.admin_policy_enabled ? merge(local.base_tags, {
    rosa_admin_role = true
    }) : (
    local.no_console_enabled ? merge(local.base_tags, {
      rosa_no_console_role = true
    }) : local.base_tags
  )
}

data "rhcs_hcp_policies" "all_policies" {}

data "rhcs_info" "current" {}

resource "aws_iam_role" "ocm_role" {
  name                  = local.role_name
  permissions_boundary  = var.permissions_boundary
  path                  = local.path
  assume_role_policy    = data.rhcs_hcp_policies.all_policies.ocm_role_policies.sts_ocm_trust_policy
  force_detach_policies = true

  tags = local.role_tags
}

resource "aws_iam_policy" "standard_permission_policy" {
  count = local.standard_policy_enabled ? 1 : 0

  name   = substr("${local.role_name}-Policy", 0, local.max_policy_name_length)
  path   = local.path
  policy = data.rhcs_hcp_policies.all_policies.ocm_role_policies.sts_ocm_permission_policy

  tags = local.base_tags
}

resource "aws_iam_role_policy_attachment" "standard_permission_policy_attachment" {
  count = local.standard_policy_enabled ? 1 : 0

  role       = aws_iam_role.ocm_role.name
  policy_arn = aws_iam_policy.standard_permission_policy[0].arn
}

resource "aws_iam_policy" "ocm_admin_permission_policy" {
  count = local.admin_policy_enabled ? 1 : 0

  name   = substr("${local.role_name}-Admin-Policy", 0, local.max_policy_name_length)
  path   = local.path
  policy = data.rhcs_hcp_policies.all_policies.ocm_role_policies.sts_ocm_admin_permission_policy

  tags = merge(local.base_tags, {
    rosa_admin_role = true
  })
}

resource "aws_iam_role_policy_attachment" "ocm_admin_permission_policy_attachment" {
  count = local.admin_policy_enabled ? 1 : 0

  role       = aws_iam_role.ocm_role.name
  policy_arn = aws_iam_policy.ocm_admin_permission_policy[0].arn
}

resource "aws_iam_policy" "ocm_no_console_permission_policy" {
  count = local.no_console_enabled ? 1 : 0

  name   = substr("${local.role_name}-NoConsole-Policy", 0, local.max_policy_name_length)
  path   = local.path
  policy = data.rhcs_hcp_policies.all_policies.ocm_role_policies.sts_ocm_no_console_permission_policy

  tags = merge(local.base_tags, {
    rosa_no_console_role = true
  })
}

resource "aws_iam_role_policy_attachment" "ocm_no_console_permission_policy_attachment" {
  count = local.no_console_enabled ? 1 : 0

  role       = aws_iam_role.ocm_role.name
  policy_arn = aws_iam_policy.ocm_no_console_permission_policy[0].arn
}

resource "rhcs_rosa_ocm_role_link" "this" {
  count = var.create_link ? 1 : 0

  role_arn = aws_iam_role.ocm_role.arn
}

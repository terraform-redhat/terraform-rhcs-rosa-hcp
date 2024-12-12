locals {
  path = coalesce(var.path, "/")
  account_roles_properties = [
    {
      role_name            = "HCP-ROSA-Installer"
      role_type            = "installer"
      policy_details       = "arn:aws:iam::aws:policy/service-role/ROSAInstallerPolicy"
      principal_type       = "AWS"
      principal_identifier = "arn:${data.aws_partition.current.partition}:iam::${data.rhcs_info.current.ocm_aws_account_id}:role/RH-Managed-OpenShift-Installer"
    },
    {
      role_name      = "HCP-ROSA-Support"
      role_type      = "support"
      policy_details = "arn:aws:iam::aws:policy/service-role/ROSASRESupportPolicy"
      principal_type = "AWS"
      // This is a SRE RH Support role which is used to assume this support role
      principal_identifier = data.rhcs_hcp_policies.all_policies.account_role_policies["sts_support_rh_sre_role"]
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
  account_role_prefix_valid = (var.account_role_prefix != null && var.account_role_prefix != "") ? (
    var.account_role_prefix
    ) : (
    "account-role-${random_string.default_random[0].result}"
  )

  route53_shared_role_arn = var.shared_vpc_roles["route53"]
  route53_splits          = split("/", local.route53_shared_role_arn)
  route53_role_name       = local.route53_splits[length(local.route53_splits) - 1]
  route53_policy_name     = substr("${local.route53_role_name}-assume-role", 0, 64)
  vpce_shared_role_arn    = var.shared_vpc_roles["vpce"]
  vpce_splits             = split("/", local.vpce_shared_role_arn)
  vpce_role_name          = local.vpce_splits[length(local.vpce_splits) - 1]
  vpce_policy_name        = substr("${local.vpce_role_name}-assume-role", 0, 64)

  policy_arn_base = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy"
}

data "aws_caller_identity" "current" {}

data "rhcs_hcp_policies" "all_policies" {}

data "aws_partition" "current" {}

data "rhcs_info" "current" {}

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

resource "aws_iam_role_policy_attachment" "worker_role_zero_egress_policy_attachment" {
  count      = var.attach_worker_role_zero_egress_policy ? 1 : 0
  role       = aws_iam_role.account_role[2].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "random_string" "default_random" {
  count = (var.account_role_prefix != null && var.account_role_prefix != "") ? 0 : 1

  length  = 4
  special = false
  upper   = false
}

### Shared VPC resources
resource "aws_iam_policy" "route53_policy" {
  count = (local.route53_shared_role_arn != "" && var.create_shared_vpc_policies) ? 1 : 0

  name = local.route53_policy_name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AssumeInto",
        "Effect" : "Allow",
        "Action" : "sts:AssumeRole",
        "Resource" : "${local.route53_shared_role_arn}"
      }
    ]
  })
  path = local.path
  tags = merge(var.tags, {
    red-hat-managed = true,
    hcp-shared-vpc  = true
  })
}

resource "aws_iam_policy" "vpce_policy" {
  count = (local.vpce_shared_role_arn != "" && var.create_shared_vpc_policies) ? 1 : 0

  name = local.vpce_policy_name
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AssumeInto",
        "Effect" : "Allow",
        "Action" : "sts:AssumeRole",
        "Resource" : "${local.vpce_shared_role_arn}"
      }
    ]
  })
  path = local.path
  tags = merge(var.tags, {
    red-hat-managed = true,
    hcp-shared-vpc  = true
  })
}

resource "aws_iam_role_policy_attachment" "route53_policy_installer_account_role_attachment" {
  count      = local.route53_shared_role_arn != "" ? 1 : 0
  role       = aws_iam_role.account_role[0].name
  policy_arn = var.create_shared_vpc_policies ? aws_iam_policy.route53_policy[0].arn : "${local.policy_arn_base}${local.path}${local.route53_policy_name}"
}

resource "aws_iam_role_policy_attachment" "vpce_policy_installer_account_role_attachment" {
  count      = local.vpce_shared_role_arn != "" ? 1 : 0
  role       = aws_iam_role.account_role[0].name
  policy_arn = var.create_shared_vpc_policies ? aws_iam_policy.vpce_policy[0].arn : "${local.policy_arn_base}${local.path}${local.vpce_policy_name}"
}


### Outputs
resource "time_sleep" "account_iam_resources_wait" {
  destroy_duration = "10s"
  create_duration  = "10s"
  triggers = {
    account_iam_role_name         = jsonencode([for value in aws_iam_role.account_role : value.name])
    account_roles_arn             = jsonencode({ for idx, value in aws_iam_role.account_role : local.account_roles_properties[idx].role_name => value.arn })
    account_policy_arns           = jsonencode([for value in aws_iam_role_policy_attachment.account_role_policy_attachment : value.policy_arn])
    account_role_prefix           = local.account_role_prefix_valid
    path                          = local.path
    shared_vpc_policy_attachments = local.route53_shared_role_arn != "" && local.vpce_shared_role_arn != "" ? jsonencode([aws_iam_role_policy_attachment.route53_policy_installer_account_role_attachment[0].policy_arn, aws_iam_role_policy_attachment.vpce_policy_installer_account_role_attachment[0].policy_arn]) : jsonencode([])
  }
}

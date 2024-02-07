data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  sts_roles = {
    role_arn         = var.installer_role_arn,
    support_role_arn = var.support_role_arn,
    instance_iam_roles = {
      worker_role_arn = var.worker_role_arn
    },
    operator_role_prefix = var.operator_role_prefix,
    oidc_config_id       = var.oidc_config_id
  }
}

data "aws_subnet" "provided_subnet" {
  count = length(var.aws_subnet_ids)

  id = var.aws_subnet_ids[count.index]
}

resource "rhcs_cluster_rosa_hcp" "rosa_sts_cluster" {
  name           = var.cluster_name
  cloud_region   = data.aws_region.current.name
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_billing_account_id = var.aws_billing_account_id == "" ? data.aws_caller_identity.current.account_id : var.aws_billing_account_id
  version        = var.openshift_version
  properties = {
    rosa_creator_arn = data.aws_caller_identity.current.arn
  }
  sts            = local.sts_roles
  availability_zones = length(var.availability_zones) > 0 ? (
    var.availability_zones
    ) : (
    length(var.aws_subnet_ids) > 0 ? (
      distinct(data.aws_subnet.provided_subnet[*].availability_zone)
      ) : (
      slice(data.aws_availability_zones.available.names, 0, 3)
    )
  )
  replicas       = var.replicas
  aws_subnet_ids = var.aws_subnet_ids
  compute_machine_type = var.compute_machine_type
  machine_cidr         = var.machine_cidr

  wait_for_create_complete = true
  wait_for_std_compute_nodes_complete = true
}


data "aws_availability_zones" "available" {
  state = "available"

  # New configuration to exclude Local Zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

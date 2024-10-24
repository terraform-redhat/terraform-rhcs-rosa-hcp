locals {
  path           = coalesce(var.path, "/")
  aws_account_id = var.aws_account_id == null ? data.aws_caller_identity.current[0].account_id : var.aws_account_id
  sts_roles = {
    role_arn = var.installer_role_arn != null ? (
      var.installer_role_arn
      ) : (
      "arn:aws:iam::${local.aws_account_id}:role${local.path}${var.account_role_prefix}-HCP-ROSA-Installer-Role"
    ),
    support_role_arn = var.support_role_arn != null ? (
      var.support_role_arn
      ) : (
      "arn:aws:iam::${local.aws_account_id}:role${local.path}${var.account_role_prefix}-HCP-ROSA-Support-Role"
    ),
    instance_iam_roles = {
      worker_role_arn = var.worker_role_arn != null ? (
        var.worker_role_arn
        ) : (
        "arn:aws:iam::${local.aws_account_id}:role${local.path}${var.account_role_prefix}-HCP-ROSA-Worker-Role"
      ),
    },
    operator_role_prefix = var.operator_role_prefix,
    oidc_config_id       = var.oidc_config_id
  }
  aws_account_arn = var.aws_account_arn == null ? data.aws_caller_identity.current[0].arn : var.aws_account_arn
  create_admin_user = var.create_admin_user
  admin_credentials = var.admin_credentials_username == null && var.admin_credentials_password == null ? (
    null
    ) : (
    { username = var.admin_credentials_username, password = var.admin_credentials_password }
  )
}

resource "rhcs_cluster_rosa_hcp" "rosa_hcp_cluster" {
  name                         = var.cluster_name
  version                      = var.openshift_version
  upgrade_acknowledgements_for = var.upgrade_acknowledgements_for
  private                      = var.private
  properties = merge(
    {
      rosa_creator_arn = local.aws_account_arn
    },
    var.properties
  )
  cloud_region   = var.aws_region == null ? data.aws_region.current[0].name : var.aws_region
  aws_account_id = local.aws_account_id
  aws_billing_account_id = var.aws_billing_account_id == null || var.aws_billing_account_id == "" ? (
    local.aws_account_id
  ) : (var.aws_billing_account_id)
  sts  = local.sts_roles
  tags = var.tags
  availability_zones = length(var.aws_availability_zones) > 0 ? (
    var.aws_availability_zones
    ) : (
    length(var.aws_subnet_ids) > 0 ? (
      distinct(data.aws_subnet.provided_subnet[*].availability_zone)
      ) : (
      slice(data.aws_availability_zones.available[0].names, 0, 1)
    )
  )
  aws_additional_compute_security_group_ids = var.aws_additional_compute_security_group_ids
  replicas                                  = var.replicas
  aws_subnet_ids                            = var.aws_subnet_ids
  compute_machine_type                      = var.compute_machine_type
  create_admin_user                         = local.create_admin_user
  admin_credentials                         = local.admin_credentials
  ec2_metadata_http_tokens                  = var.ec2_metadata_http_tokens

  machine_cidr = var.machine_cidr
  service_cidr = var.service_cidr
  pod_cidr     = var.pod_cidr
  host_prefix  = var.host_prefix
  proxy = var.http_proxy != null || var.https_proxy != null || var.no_proxy != null || var.additional_trust_bundle != null ? (
    {
      http_proxy              = var.http_proxy
      https_proxy             = var.https_proxy
      no_proxy                = var.no_proxy
      additional_trust_bundle = var.additional_trust_bundle
    }
    ) : (
    null
  )
  etcd_encryption  = var.etcd_encryption
  etcd_kms_key_arn = var.etcd_kms_key_arn
  kms_key_arn      = var.kms_key_arn

  wait_for_create_complete            = var.wait_for_create_complete
  wait_for_std_compute_nodes_complete = var.wait_for_std_compute_nodes_complete
  disable_waiting_in_destroy          = var.disable_waiting_in_destroy
  destroy_timeout                     = var.destroy_timeout

  lifecycle {
    precondition {
      condition = (
        !(var.installer_role_arn != null && var.support_role_arn != null && var.worker_role_arn != null)
        &&
        var.account_role_prefix == null
      ) == false
      error_message = "Either provide the \"account_role_prefix\" or specify all ARNs for account roles (\"installer_role_arn\", \"support_role_arn\", \"worker_role_arn\")."
    }
    precondition {
      condition = (
        var.installer_role_arn != null && var.support_role_arn != null &&
        var.worker_role_arn != null && var.account_role_prefix != null
      ) == false
      error_message = "The \"account_role_prefix\" shouldn't be provided when all ARNs for account roles are specified (\"installer_role_arn\", \"support_role_arn\", \"worker_role_arn\")."
    }
    precondition {
      condition = (
        (
          var.autoscaler_max_pod_grace_period != null ||
          var.autoscaler_pod_priority_threshold != null ||
          var.autoscaler_max_node_provision_time != null ||
          var.autoscaler_max_nodes_total != null
        )
        && var.cluster_autoscaler_enabled != true
      ) == false
      error_message = "Autoscaler parameters cannot be modified while the cluster autoscaler is disabled. Please ensure that cluster_autoscaler_enabled variable is set to true"
    }
  }
}

resource "rhcs_hcp_cluster_autoscaler" "cluster_autoscaler" {
  count = var.cluster_autoscaler_enabled == true ? 1 : 0

  cluster                 = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.id
  max_pod_grace_period    = var.autoscaler_max_pod_grace_period
  pod_priority_threshold  = var.autoscaler_pod_priority_threshold
  max_node_provision_time = var.autoscaler_max_node_provision_time

  resource_limits = {
    max_nodes_total = var.autoscaler_max_nodes_total
  }
}

resource "rhcs_hcp_default_ingress" "default_ingress" {
  cluster          = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.id
  listening_method = var.default_ingress_listening_method != "" ? (
    var.default_ingress_listening_method) : (
    var.private ? "internal" : "external"
  )
}

data "aws_caller_identity" "current" {
  count = var.aws_account_id == null || var.aws_account_arn == null ? 1 : 0
}

data "aws_region" "current" {
  count = var.aws_region == null ? 1 : 0
}

data "aws_availability_zones" "available" {
  count = length(var.aws_availability_zones) > 0 ? 0 : 1
  state = "available"

  # New configuration to exclude Local Zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_subnet" "provided_subnet" {
  count = length(var.aws_subnet_ids)

  id = var.aws_subnet_ids[count.index]
}

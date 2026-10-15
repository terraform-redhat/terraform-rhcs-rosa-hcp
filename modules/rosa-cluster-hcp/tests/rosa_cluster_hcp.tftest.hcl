// Copyright Red Hat
// SPDX-License-Identifier: Apache-2.0

# rhcs_hcp_default_ingress count follows var.wait_for_create_complete only (see main.tf).
# Driving count from resource attributes that can be null after import caused:
# "The condition value is null. Conditions must either be true or false."
# These plan-mode runs assert both branches: count 1 when true, count 0 when false.

mock_provider "aws" {
  alias = "default"

  mock_data "aws_partition" {
    defaults = {
      dns_suffix         = "amazonaws.com"
      id                 = "aws"
      partition          = "aws"
      reverse_dns_prefix = "amazonaws.com"
    }
  }

  mock_data "aws_subnet" {
    defaults = {
      availability_zone = "us-east-1a"
      id                = "subnet-fake12345"
    }
  }
}

mock_provider "rhcs" {
  alias           = "import_sim"
  override_during = plan

  # Partial cluster state simulation for plan (not used for default_ingress count).
  mock_resource "rhcs_cluster_rosa_hcp" {
    defaults = {
      id                       = "rhcs-fake-cluster-id"
      wait_for_create_complete = null
      channel                  = "stable-4.21"
      channel_group            = "stable"
      # Stands in for the API default applied when the module omits the field.
      ec2_metadata_http_tokens = "required"
    }
  }

  mock_resource "rhcs_hcp_default_ingress" {
    defaults = {}
  }
}

variables {
  cluster_name           = "existing-cluster"
  openshift_version      = "4.15.0"
  oidc_config_id         = "00000000000000000000000000000000"
  operator_role_prefix   = "test-operator-prefix"
  account_role_prefix    = "test-account-prefix"
  aws_subnet_ids         = ["subnet-fake12345"]
  aws_availability_zones = ["us-east-1a"]
  aws_account_id         = "123456789012"
  aws_account_arn        = "arn:aws:iam::123456789012:root"
  aws_region             = "us-east-1"
}

run "plan_default_ingress_count_when_wait_for_create_complete_true" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  assert {
    condition     = length(rhcs_hcp_default_ingress.default_ingress) == 1
    error_message = "rhcs_hcp_default_ingress.default_ingress must have count 1 when var.wait_for_create_complete is true."
  }
}

run "plan_default_ingress_count_when_wait_for_create_complete_false" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    wait_for_create_complete = false
  }

  assert {
    condition     = length(rhcs_hcp_default_ingress.default_ingress) == 0
    error_message = "rhcs_hcp_default_ingress.default_ingress must have count 0 when var.wait_for_create_complete is false."
  }
}

run "cluster_no_cni_with_default_standard_compute_waiter_fails" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    no_cni = true
  }

  expect_failures = [
    rhcs_cluster_rosa_hcp.rosa_hcp_cluster,
  ]
}

run "cluster_no_cni_without_standard_compute_waiter_is_wired" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    no_cni                              = true
    wait_for_std_compute_nodes_complete = false
    spot_termination_queue_url          = "https://sqs.us-east-1.amazonaws.com/123456789012/spot-termination"
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.no_cni == true
    error_message = "no_cni must be wired through to rhcs_cluster_rosa_hcp."
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.wait_for_std_compute_nodes_complete == false
    error_message = "no-CNI clusters must disable the standard compute node waiter."
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.spot_termination_queue_url == "https://sqs.us-east-1.amazonaws.com/123456789012/spot-termination"
    error_message = "spot_termination_queue_url must be wired through to rhcs_cluster_rosa_hcp."
  }
}

run "cluster_no_cni_false_is_wired" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    no_cni = false
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.no_cni == false
    error_message = "no_cni must preserve false when passed to rhcs_cluster_rosa_hcp."
  }
}

run "default_ingress_component_routes_populated" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    default_ingress_component_routes = {
      console = {
        hostname       = "console.apps.example.com"
        tls_secret_ref = "console-tls"
      }
      downloads = {
        hostname       = "downloads.apps.example.com"
        tls_secret_ref = "downloads-tls"
      }
    }
  }

  assert {
    condition     = rhcs_hcp_default_ingress.default_ingress[0].component_routes == var.default_ingress_component_routes
    error_message = "component_routes must be wired through to rhcs_hcp_default_ingress."
  }
}

run "default_ingress_component_routes_partial" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    default_ingress_component_routes = {
      console = {
        hostname       = "console.apps.example.com"
        tls_secret_ref = "console-tls"
      }
    }
  }

  assert {
    condition     = rhcs_hcp_default_ingress.default_ingress[0].component_routes == var.default_ingress_component_routes
    error_message = "component_routes must allow configuring only selected ingress components."
  }
}

run "default_ingress_component_routes_omitted" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    default_ingress_component_routes = null
  }

  assert {
    condition     = rhcs_hcp_default_ingress.default_ingress[0].component_routes == null
    error_message = "component_routes must remain unset when omitted."
  }
}

# channel variable validation: cannot be used together with version_channel_group.
run "both_channel_and_version_channel_group_fails" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    channel               = "stable-4.16"
    version_channel_group = "stable"
  }

  expect_failures = [
    rhcs_cluster_rosa_hcp.rosa_hcp_cluster,
  ]
}

# Valid plan when only channel is set.
run "valid_plan_with_only_channel" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    channel = "stable-4.16"
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.channel == "stable-4.16"
    error_message = "rhcs_cluster_rosa_hcp.rosa_hcp_cluster.channel must be 'stable-4.16' when only channel is set."
  }
}

# Valid plan when only version_channel_group is set.
run "valid_plan_with_only_version_channel_group" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    version_channel_group = "stable"
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.channel_group == "stable"
    error_message = "rhcs_cluster_rosa_hcp.rosa_hcp_cluster.channel_group must be 'stable' when only version_channel_group is set."
  }
}

# Valid plan when both channel and version_channel_group are null (API defaults).
run "valid_plan_with_both_null" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    channel               = null
    version_channel_group = null
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.channel == "stable-4.21"
    error_message = "rhcs_cluster_rosa_hcp.rosa_hcp_cluster.channel must be 'stable-4.21' (API default) when both channel and version_channel_group are null."
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.channel_group == "stable"
    error_message = "rhcs_cluster_rosa_hcp.rosa_hcp_cluster.channel_group must be 'stable' (API default) when both channel and version_channel_group are null."
  }
}

# channel format validation: missing version number
run "invalid_channel_missing_version" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    channel = "stable"
  }

  expect_failures = [
    var.channel,
  ]
}

# channel format validation: unsupported channel group
run "invalid_channel_wrong_group" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    channel = "testing-4.16"
  }

  expect_failures = [
    var.channel,
  ]
}

# channel format validation: three-part version number
run "invalid_channel_three_part_version" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    channel = "stable-4.16.1"
  }

  expect_failures = [
    var.channel,
  ]
}

# worker_disk_size passthrough: null value (platform default).
run "worker_disk_size_null" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    worker_disk_size = null
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.worker_disk_size == null
    error_message = "worker_disk_size must be null when set to null (platform default)."
  }
}

# worker_disk_size passthrough: explicit value (400 GiB).
run "worker_disk_size_explicit" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    worker_disk_size = 400
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.worker_disk_size == 400
    error_message = "worker_disk_size must be 400 when explicitly set to 400."
  }
}

# delete_protection passthrough: null value (provider defaults to false).
run "delete_protection_null" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    delete_protection = null
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.delete_protection == false
    error_message = "delete_protection must be false when unset."
  }
}

# delete_protection passthrough: explicit true.
run "delete_protection_enabled" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    delete_protection = true
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.delete_protection == true
    error_message = "delete_protection must be true when explicitly enabled."
  }
}

# delete_protection passthrough: explicit false.
run "delete_protection_disabled" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    delete_protection = false
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.delete_protection == false
    error_message = "delete_protection must be false when explicitly disabled."
  }
}

# ec2_metadata_http_tokens passthrough: unset must leave the value to the API, not force 'optional'.
run "ec2_metadata_http_tokens_unset" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  assert {
    condition     = var.ec2_metadata_http_tokens == null
    error_message = "ec2_metadata_http_tokens must default to null so the module sends nothing."
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.ec2_metadata_http_tokens == "required"
    error_message = "Unset ec2_metadata_http_tokens must take the API-computed value, not a module-forced 'optional'."
  }
}

# ec2_metadata_http_tokens passthrough: explicit optional (IMDS v1 or v2).
run "ec2_metadata_http_tokens_optional" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    ec2_metadata_http_tokens = "optional"
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.ec2_metadata_http_tokens == "optional"
    error_message = "ec2_metadata_http_tokens must be 'optional' when explicitly set to 'optional'."
  }
}

# ec2_metadata_http_tokens passthrough: explicit required (IMDSv2 only).
run "ec2_metadata_http_tokens_required" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    ec2_metadata_http_tokens = "required"
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.ec2_metadata_http_tokens == "required"
    error_message = "ec2_metadata_http_tokens must be 'required' when explicitly set to 'required'."
  }
}

# ec2_metadata_http_tokens enum validation: value outside required/optional.
run "invalid_ec2_metadata_http_tokens" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    ec2_metadata_http_tokens = "wrong"
  }

  expect_failures = [
    var.ec2_metadata_http_tokens,
  ]
}

##############################################################
# H1 — max wait timeouts (max_hcp_cluster_wait_timeout_in_minutes,
# max_machinepool_wait_timeout_in_minutes). Both are provider Int64
# Optional (non-computed) attributes, so the configured value plans
# deterministically. Covers null/unset and set passthrough across the
# wait_for_create_complete / wait_for_std_compute_nodes_complete branches.
##############################################################

# Both timeouts unset: provider defaults (45 / 60) apply; attributes plan as null.
run "max_wait_timeouts_unset_passthrough" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.max_hcp_cluster_wait_timeout_in_minutes == null
    error_message = "max_hcp_cluster_wait_timeout_in_minutes must remain null when unset (provider default of 45 minutes applies)."
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.max_machinepool_wait_timeout_in_minutes == null
    error_message = "max_machinepool_wait_timeout_in_minutes must remain null when unset (provider default of 60 minutes applies)."
  }
}

# Both timeouts set with both waiters at their defaults (true): values wire through.
run "max_wait_timeouts_set_passthrough" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    max_hcp_cluster_wait_timeout_in_minutes = 90
    max_machinepool_wait_timeout_in_minutes = 90
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.max_hcp_cluster_wait_timeout_in_minutes == 90
    error_message = "max_hcp_cluster_wait_timeout_in_minutes must be wired through to rhcs_cluster_rosa_hcp as 90."
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.max_machinepool_wait_timeout_in_minutes == 90
    error_message = "max_machinepool_wait_timeout_in_minutes must be wired through to rhcs_cluster_rosa_hcp as 90."
  }
}

# wait_for_create_complete=false branch: timeout is still accepted and wired through.
run "max_wait_timeouts_with_create_waiter_disabled" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    wait_for_create_complete                = false
    wait_for_std_compute_nodes_complete     = false
    max_hcp_cluster_wait_timeout_in_minutes = 90
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.wait_for_create_complete == false
    error_message = "wait_for_create_complete must be false in this branch."
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.max_hcp_cluster_wait_timeout_in_minutes == 90
    error_message = "max_hcp_cluster_wait_timeout_in_minutes must still wire through when wait_for_create_complete is false."
  }
}

# wait_for_std_compute_nodes_complete=false while wait_for_create_complete=true:
# the machine pool timeout is still accepted and wired through.
run "max_wait_timeouts_with_std_compute_waiter_disabled" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    wait_for_create_complete                = true
    wait_for_std_compute_nodes_complete     = false
    max_machinepool_wait_timeout_in_minutes = 90
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.wait_for_std_compute_nodes_complete == false
    error_message = "wait_for_std_compute_nodes_complete must be false in this branch."
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.max_machinepool_wait_timeout_in_minutes == 90
    error_message = "max_machinepool_wait_timeout_in_minutes must still wire through when wait_for_std_compute_nodes_complete is false."
  }
}

# Both waiters true with both timeouts set: full passthrough.
run "max_wait_timeouts_both_waiters_enabled" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    wait_for_create_complete                = true
    wait_for_std_compute_nodes_complete     = true
    max_hcp_cluster_wait_timeout_in_minutes = 90
    max_machinepool_wait_timeout_in_minutes = 90
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.max_hcp_cluster_wait_timeout_in_minutes == 90
    error_message = "max_hcp_cluster_wait_timeout_in_minutes must wire through when both waiters are enabled."
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.max_machinepool_wait_timeout_in_minutes == 90
    error_message = "max_machinepool_wait_timeout_in_minutes must wire through when both waiters are enabled."
  }
}

##############################################################
# H4 — audit_log_arn pass-through. Provider StringAttribute (Optional,
# non-computed): null leaves forwarding disabled, a set ARN enables it,
# and an empty string disables it on a day-2 update. All three plan
# deterministically.
##############################################################

# Null: forwarding disabled; attribute plans as null.
run "audit_log_arn_null_passthrough" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    audit_log_arn = null
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.audit_log_arn == null
    error_message = "audit_log_arn must remain null when unset (forwarding disabled)."
  }
}

# Set ARN: wires through to enable forwarding.
run "audit_log_arn_set_passthrough" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    audit_log_arn = "arn:aws:iam::123456789012:role/audit-exporter"
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.audit_log_arn == "arn:aws:iam::123456789012:role/audit-exporter"
    error_message = "audit_log_arn must be wired through to rhcs_cluster_rosa_hcp."
  }
}

# Empty string is a meaningful value (day-2 disable): must remain "" and pass validation.
run "audit_log_arn_empty_string_passthrough" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.import_sim
  }

  variables {
    audit_log_arn = ""
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.audit_log_arn == ""
    error_message = "audit_log_arn must preserve an empty string (day-2 disable) when passed to rhcs_cluster_rosa_hcp."
  }
}

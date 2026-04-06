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
    var.channel,
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

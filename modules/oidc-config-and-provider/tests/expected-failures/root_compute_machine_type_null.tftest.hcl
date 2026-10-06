// Copyright Red Hat
// SPDX-License-Identifier: Apache-2.0

# This test is intentionally outside the default test directory. The shell
# harness runs it separately and verifies the real root module's existing
# for_each rejects an explicitly null machine_pools value.

mock_provider "aws" {
  override_during = plan

  mock_data "aws_partition" {
    defaults = {
      dns_suffix         = "amazonaws.com"
      id                 = "aws"
      partition          = "aws"
      reverse_dns_prefix = "amazonaws.com"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:root"
      id         = "123456789012"
      user_id    = "mock-user"
    }
  }

  mock_data "aws_subnet" {
    defaults = {
      availability_zone = "us-east-1a"
      id                = "subnet-fake12345"
    }
  }

  mock_data "aws_region" {
    defaults = {
      id     = "us-east-1"
      name   = "us-east-1"
      region = "us-east-1"
    }
  }
}

mock_provider "rhcs" {
  override_during = plan

  mock_resource "rhcs_cluster_rosa_hcp" {
    defaults = {
      compute_machine_type = null
      id                   = "rhcs-fake-cluster-id"
    }
  }

  mock_resource "rhcs_hcp_machine_pool" {
    defaults = {
      id = "rhcs-fake-machine-pool-id"
    }
  }
}

mock_provider "null" {}

run "untargeted_null_machine_pools_is_invalid" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    cluster_name                        = "compute-type-test"
    openshift_version                   = "4.20.0"
    oidc_config_id                      = "00000000000000000000000000000000"
    aws_subnet_ids                      = ["subnet-fake12345"]
    aws_availability_zones              = ["us-east-1a"]
    wait_for_create_complete            = false
    wait_for_std_compute_nodes_complete = false
    compute_machine_type                = null
    machine_pools                       = null
  }
}

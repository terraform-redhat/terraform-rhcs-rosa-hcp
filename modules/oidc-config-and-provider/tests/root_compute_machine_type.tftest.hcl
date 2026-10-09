// Copyright Red Hat
// SPDX-License-Identifier: Apache-2.0

# These runs select the repository root module. The accompanying shell harness
# inspects their machine-readable plans to assert the nested RHCS cluster
# resource argument without adding a public output solely for test visibility.

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

variables {
  cluster_name                        = "compute-type-test"
  openshift_version                   = "4.20.0"
  oidc_config_id                      = "00000000000000000000000000000000"
  aws_subnet_ids                      = ["subnet-fake12345"]
  aws_availability_zones              = ["us-east-1a"]
  wait_for_create_complete            = false
  wait_for_std_compute_nodes_complete = false
}

run "null_uses_one_machine_pool_type" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    compute_machine_type = null
    machine_pools = {
      workers = {
        name              = "workers"
        subnet_id         = "subnet-fake12345"
        openshift_version = "4.20.0"
        auto_repair       = true
        aws_node_pool = {
          instance_type = "m5.xlarge"
          tags          = {}
        }
      }
    }
  }
}

run "null_uses_same_type_from_multiple_machine_pools" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    compute_machine_type = null
    machine_pools = {
      z-workers = {
        name              = "z-workers"
        subnet_id         = "subnet-fake12345"
        openshift_version = "4.20.0"
        auto_repair       = true
        aws_node_pool = {
          instance_type = "m5.xlarge"
          tags          = {}
        }
      }
      a-workers = {
        name              = "a-workers"
        subnet_id         = "subnet-fake12345"
        openshift_version = "4.20.0"
        auto_repair       = true
        aws_node_pool = {
          instance_type = "m5.xlarge"
          tags          = {}
        }
      }
    }
  }
}

run "explicit_type_wins_over_machine_pool_type" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    # This mocked plan proves root-module precedence only. A real provider or
    # API conflict between default and additional pool types is unchanged.
    compute_machine_type = "m7i.xlarge"
    machine_pools = {
      workers = {
        name              = "workers"
        subnet_id         = "subnet-fake12345"
        openshift_version = "4.20.0"
        auto_repair       = true
        aws_node_pool = {
          instance_type = "m5.xlarge"
          tags          = {}
        }
      }
    }
  }
}

run "null_with_empty_machine_pools_stays_null" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    compute_machine_type = null
    machine_pools        = {}
  }
}

run "explicit_type_with_empty_machine_pools" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    compute_machine_type = "m5.xlarge"
    machine_pools        = {}
  }
}

# Targeting the cluster module lets this run inspect the real root expression
# and nested cluster resource while preserving the existing machine-pool
# for_each. The shell harness separately verifies that an ordinary untargeted
# real-root plan rejects the same explicit null at that unchanged for_each.
run "null_with_explicitly_null_machine_pools" {
  command = plan

  module {
    source = "../.."
  }

  plan_options {
    target = [module.rosa_cluster_hcp]
  }

  variables {
    compute_machine_type = null
    machine_pools        = null
  }
}

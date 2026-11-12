// Copyright Red Hat
// SPDX-License-Identifier: Apache-2.0

// Root-module type tests for machine_pools[*].aws_node_pool.tags.
// Child-module wiring tests live in modules/machine-pool/tests/.

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

  # Pins the region so the availability zone matches it during plan.
  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
      name   = "us-east-1"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:root"
      id         = "123456789012"
    }
  }
}

mock_provider "rhcs" {
  alias = "default"
}

mock_provider "null" {
  alias = "default"
}

variables {
  cluster_name           = "test-cluster"
  openshift_version      = "4.20.0"
  aws_subnet_ids         = ["subnet-fake12345"]
  aws_availability_zones = ["us-east-1a"]
  create_oidc            = true
  create_operator_roles  = false
  create_account_roles   = false
}

# tags omitted: the root type accepts an aws_node_pool without tags and sets it to null.
run "root_machine_pool_tags_omitted_plan" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.default
    null = null.default
  }

  variables {
    machine_pools = {
      untagged = {
        name              = "untagged"
        subnet_id         = "subnet-fake12345"
        openshift_version = "4.20.0"
        auto_repair       = true
        replicas          = 2
        aws_node_pool = {
          instance_type = "m5.xlarge"
        }
      }
    }
  }

  assert {
    condition     = var.machine_pools["untagged"].aws_node_pool.tags == null
    error_message = "Omitted aws_node_pool.tags must become null in the root machine_pools type."
  }
}

# tags = {}: a managed empty set must stay an empty map, not collapse to null.
run "root_machine_pool_tags_empty_map_plan" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.default
    null = null.default
  }

  variables {
    machine_pools = {
      emptytags = {
        name              = "emptytags"
        subnet_id         = "subnet-fake12345"
        openshift_version = "4.20.0"
        auto_repair       = true
        replicas          = 2
        aws_node_pool = {
          instance_type = "m5.xlarge"
          tags          = {}
        }
      }
    }
  }

  assert {
    condition     = var.machine_pools["emptytags"].aws_node_pool.tags != null && length(var.machine_pools["emptytags"].aws_node_pool.tags) == 0
    error_message = "aws_node_pool.tags = {} must stay an empty map in the root machine_pools type."
  }
}

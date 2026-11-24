// Copyright Red Hat
// SPDX-License-Identifier: Apache-2.0

// Root-module type tests for machine_pools[*].aws_node_pool.tags.
// The tags field is optional, so a machine pool can leave its tags unmanaged
// (omitted) or let Terraform manage the complete machine-pool-specific set
// (a map, empty included). These runs check that the root variable type accepts
// each shape and that the root plan still succeeds; a required tags attribute
// in the root type fails them. terraform test cannot assert on a child module's
// resources, so the tag values that reach rhcs_hcp_machine_pool are asserted in
// modules/machine-pool/tests/aws_node_pool.tftest.hcl.

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

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
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

# tags omitted: the root type accepts an aws_node_pool object without tags, and
# the omitted attribute becomes null rather than failing the plan.
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
        name              = "untagged-pool"
        subnet_id         = "subnet-fake12345"
        openshift_version = "4.20.0"
        aws_node_pool = {
          instance_type = "m5.xlarge"
        }
        replicas = 2
        # The provider marks auto_repair required, and the root module passes
        # this field through as-is, so each pool sets it explicitly.
        auto_repair = true
      }
    }
  }

  assert {
    condition     = var.machine_pools["untagged"].aws_node_pool.tags == null
    error_message = "Omitting tags must leave the machine pool input null so the root module sends nothing."
  }
}

# tags set to an empty map: a managed empty set is a valid root input and stays
# an empty map rather than collapsing to the omitted (unmanaged) shape.
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
        name              = "empty-tags-pool"
        subnet_id         = "subnet-fake12345"
        openshift_version = "4.20.0"
        aws_node_pool = {
          instance_type = "m5.xlarge"
          tags          = {}
        }
        replicas = 2
        # The provider marks auto_repair required, and the root module passes
        # this field through as-is, so each pool sets it explicitly.
        auto_repair = true
      }
    }
  }

  assert {
    condition = (
      var.machine_pools["emptytags"].aws_node_pool.tags != null &&
      length(var.machine_pools["emptytags"].aws_node_pool.tags) == 0
    )
    error_message = "An empty tags map must stay an empty map on the root input, not become null."
  }
}

# tags set: a populated map is accepted by the root type and preserved.
run "root_machine_pool_tags_set_plan" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.default
    null = null.default
  }

  variables {
    machine_pools = {
      tagged = {
        name              = "tagged-pool"
        subnet_id         = "subnet-fake12345"
        openshift_version = "4.20.0"
        aws_node_pool = {
          instance_type = "m5.xlarge"
          tags = {
            environment = "staging"
          }
        }
        replicas = 2
        # The provider marks auto_repair required, and the root module passes
        # this field through as-is, so each pool sets it explicitly.
        auto_repair = true
      }
    }
  }

  assert {
    condition = (
      var.machine_pools["tagged"].aws_node_pool.tags["environment"] == "staging" &&
      length(var.machine_pools["tagged"].aws_node_pool.tags) == 1
    )
    error_message = "A populated tags map must be preserved on the root input."
  }
}

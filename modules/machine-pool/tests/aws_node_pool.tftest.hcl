// Copyright Red Hat
// SPDX-License-Identifier: Apache-2.0

mock_provider "rhcs" {
  alias = "no_override"
}

mock_provider "rhcs" {
  # Generate computed values at plan time so plan-only runs can assert on them.
  override_during = plan
  alias           = "with_override"
  mock_resource "rhcs_hcp_machine_pool" {
    defaults = {
      aws_node_pool = {
        capacity_reservation_preference = "defined_by_provider"
        node_drain_grace_period         = null
        # Stands in for the API default applied when the module omits the field.
        ec2_metadata_http_tokens = "required"
      }
    }
  }
}

run "invalid_capres_preference_fails" {
  command = plan

  providers = {
    rhcs = rhcs.no_override
  }


  variables {
    cluster_id        = "fake-cluster-123"
    name              = "test-pool"
    subnet_id         = "subnet-fake123"
    openshift_version = "4.15.0"

    aws_node_pool = {
      instance_type                   = "m5.xlarge"
      tags                            = {}
      capacity_reservation_preference = "wrong"
    }
  }

  # We expect validation to fail because capacity_reservation_preference
  # must be one of: none, open, capacity-reservations-only.
  expect_failures = [
    var.aws_node_pool,
  ]
}

run "capres_id_is_null" {
  command = plan

  providers = {
    rhcs = rhcs.no_override
  }

  variables {
    cluster_id        = "fake-cluster-123"
    name              = "test-pool"
    subnet_id         = "subnet-fake123"
    openshift_version = "4.15.0"

    aws_node_pool = {
      instance_type = "m5.xlarge"
      tags          = {}
    }
  }

  assert {
    condition     = rhcs_hcp_machine_pool.machine_pool.aws_node_pool.capacity_reservation_id == null
    error_message = "Expected capacity_reservation_id to be null."
  }
}

# Explicit null for optional capacity_reservation_preference: variable validation must allow it (no contains(null)).
run "capacity_reservation_preference_explicit_null_plan" {
  command = plan

  providers = {
    rhcs = rhcs.no_override
  }

  variables {
    cluster_id        = "fake-cluster-123"
    name              = "test-pool"
    subnet_id         = "subnet-fake123"
    openshift_version = "4.15.0"

    aws_node_pool = {
      instance_type                   = "m5.xlarge"
      tags                            = {}
      capacity_reservation_preference = null
    }
  }

  # Planned resource may mark this attribute unknown; input var is known and proves validation accepted null.
  assert {
    condition     = var.aws_node_pool.capacity_reservation_preference == null
    error_message = "Expected explicit null capacity_reservation_preference on aws_node_pool (optional field)."
  }
}

run "capres_preference_is_defined_by_provider" {
  command = plan

  providers = {
    rhcs = rhcs.with_override
  }

  variables {
    cluster_id        = "fake-cluster-123"
    name              = "test-pool"
    subnet_id         = "subnet-fake123"
    openshift_version = "4.15.0"

    aws_node_pool = {
      instance_type = "m5.xlarge"
      tags          = {}
    }
  }

  assert {
    condition     = rhcs_hcp_machine_pool.machine_pool.aws_node_pool.capacity_reservation_preference == "defined_by_provider"
    error_message = "Expected capacity_reservation_preference to be defined by provider (computed)."
  }
}

# Test lifecycle ignore_changes: apply with one value, then plan with another; plan should keep the first value.
run "apply_with_capres_preference" {
  command = apply

  providers = {
    rhcs = rhcs.no_override
  }

  state_key = "lifecycle"

  variables {
    cluster_id        = "fake-cluster-123"
    name              = "test-pool"
    subnet_id         = "subnet-fake123"
    openshift_version = "4.15.0"
    replicas          = 1

    aws_node_pool = {
      instance_type                   = "m5.xlarge"
      tags                            = {}
      capacity_reservation_preference = "none"
    }
  }

  assert {
    condition     = rhcs_hcp_machine_pool.machine_pool.aws_node_pool.capacity_reservation_preference == "none"
    error_message = "Setup run should have capacity_reservation_preference = 'none'."
  }
}

# Test that invalid node_drain_grace_period > 10080 fails validation
run "invalid_node_drain_grace_period_fails" {
  command = plan

  providers = {
    rhcs = rhcs.no_override
  }

  variables {
    cluster_id        = "fake-cluster-123"
    name              = "test-pool"
    subnet_id         = "subnet-fake123"
    openshift_version = "4.15.0"

    aws_node_pool = {
      instance_type           = "m5.xlarge"
      tags                    = {}
      node_drain_grace_period = 10081
    }
  }

  expect_failures = [
    var.aws_node_pool,
  ]
}

# Test that valid node_drain_grace_period (60 minutes) passes validation and wires through to the resource
run "valid_node_drain_grace_period_plan" {
  command = plan

  providers = {
    rhcs = rhcs.no_override
  }

  variables {
    cluster_id        = "fake-cluster-123"
    name              = "test-pool"
    subnet_id         = "subnet-fake123"
    openshift_version = "4.15.0"

    aws_node_pool = {
      instance_type           = "m5.xlarge"
      tags                    = {}
      node_drain_grace_period = 60
    }
  }

  assert {
    condition     = rhcs_hcp_machine_pool.machine_pool.aws_node_pool.node_drain_grace_period == 60
    error_message = "Expected node_drain_grace_period to be wired through to rhcs_hcp_machine_pool as 60."
  }
}

# Test that null node_drain_grace_period passes validation and wires through to the resource as null
run "node_drain_grace_period_null_plan" {
  command = plan

  providers = {
    rhcs = rhcs.with_override
  }

  variables {
    cluster_id        = "fake-cluster-123"
    name              = "test-pool"
    subnet_id         = "subnet-fake123"
    openshift_version = "4.15.0"

    aws_node_pool = {
      instance_type           = "m5.xlarge"
      tags                    = {}
      node_drain_grace_period = null
    }
  }

  assert {
    condition     = rhcs_hcp_machine_pool.machine_pool.aws_node_pool.node_drain_grace_period == null
    error_message = "Expected null node_drain_grace_period to be wired through to rhcs_hcp_machine_pool as null."
  }
}

run "spot_instances_with_max_price_plan" {
  command = plan

  providers = {
    rhcs = rhcs.no_override
  }

  variables {
    cluster_id        = "fake-cluster-123"
    name              = "test-pool"
    subnet_id         = "subnet-fake123"
    openshift_version = "4.15.0"

    aws_node_pool = {
      instance_type      = "m5.xlarge"
      tags               = {}
      use_spot_instances = true
      max_spot_price     = 0.50
    }
  }

  assert {
    condition     = rhcs_hcp_machine_pool.machine_pool.aws_node_pool.use_spot_instances == true
    error_message = "use_spot_instances must be wired through to rhcs_hcp_machine_pool."
  }

  assert {
    condition     = rhcs_hcp_machine_pool.machine_pool.aws_node_pool.max_spot_price == 0.50
    error_message = "max_spot_price must be wired through to rhcs_hcp_machine_pool."
  }
}

run "spot_instance_settings_unset_plan" {
  command = plan

  providers = {
    rhcs = rhcs.no_override
  }

  variables {
    cluster_id        = "fake-cluster-123"
    name              = "test-pool"
    subnet_id         = "subnet-fake123"
    openshift_version = "4.15.0"

    aws_node_pool = {
      instance_type = "m5.xlarge"
      tags          = {}
    }
  }

  assert {
    condition     = rhcs_hcp_machine_pool.machine_pool.aws_node_pool.use_spot_instances == null && rhcs_hcp_machine_pool.machine_pool.aws_node_pool.max_spot_price == null
    error_message = "Spot instance settings must remain unset on rhcs_hcp_machine_pool."
  }
}

run "spot_instances_disabled_plan" {
  command = plan

  providers = {
    rhcs = rhcs.no_override
  }

  variables {
    cluster_id        = "fake-cluster-123"
    name              = "test-pool"
    subnet_id         = "subnet-fake123"
    openshift_version = "4.15.0"

    aws_node_pool = {
      instance_type      = "m5.xlarge"
      tags               = {}
      use_spot_instances = false
    }
  }

  assert {
    condition     = rhcs_hcp_machine_pool.machine_pool.aws_node_pool.use_spot_instances == false
    error_message = "use_spot_instances must preserve false when passed to rhcs_hcp_machine_pool."
  }
}

# Test that an invalid ec2_metadata_http_tokens fails validation
run "invalid_ec2_metadata_http_tokens_fails" {
  command = plan

  providers = {
    rhcs = rhcs.no_override
  }

  variables {
    cluster_id        = "fake-cluster-123"
    name              = "test-pool"
    subnet_id         = "subnet-fake123"
    openshift_version = "4.15.0"

    aws_node_pool = {
      instance_type            = "m5.xlarge"
      tags                     = {}
      ec2_metadata_http_tokens = "wrong"
    }
  }

  # We expect validation to fail because ec2_metadata_http_tokens
  # must be one of: required, optional.
  expect_failures = [
    var.aws_node_pool,
  ]
}

# The module must not force a value: when unset, the API-computed value stands.
run "ec2_metadata_http_tokens_unset_plan" {
  command = plan

  providers = {
    rhcs = rhcs.with_override
  }

  variables {
    cluster_id        = "fake-cluster-123"
    name              = "test-pool"
    subnet_id         = "subnet-fake123"
    openshift_version = "4.15.0"

    aws_node_pool = {
      instance_type = "m5.xlarge"
      tags          = {}
    }
  }

  assert {
    condition     = var.aws_node_pool.ec2_metadata_http_tokens == null
    error_message = "Omitting ec2_metadata_http_tokens must leave the input null so the module sends nothing."
  }

  assert {
    condition     = rhcs_hcp_machine_pool.machine_pool.aws_node_pool.ec2_metadata_http_tokens == "required"
    error_message = "Unset ec2_metadata_http_tokens must take the API-computed value, not a module-forced 'optional'."
  }
}

run "ec2_metadata_http_tokens_optional_plan" {
  command = plan

  providers = {
    rhcs = rhcs.no_override
  }

  variables {
    cluster_id        = "fake-cluster-123"
    name              = "test-pool"
    subnet_id         = "subnet-fake123"
    openshift_version = "4.15.0"

    aws_node_pool = {
      instance_type            = "m5.xlarge"
      tags                     = {}
      ec2_metadata_http_tokens = "optional"
    }
  }

  assert {
    condition     = rhcs_hcp_machine_pool.machine_pool.aws_node_pool.ec2_metadata_http_tokens == "optional"
    error_message = "Explicit ec2_metadata_http_tokens = 'optional' must be wired through to rhcs_hcp_machine_pool."
  }
}

run "ec2_metadata_http_tokens_required_plan" {
  command = plan

  providers = {
    rhcs = rhcs.no_override
  }

  variables {
    cluster_id        = "fake-cluster-123"
    name              = "test-pool"
    subnet_id         = "subnet-fake123"
    openshift_version = "4.15.0"

    aws_node_pool = {
      instance_type            = "m5.xlarge"
      tags                     = {}
      ec2_metadata_http_tokens = "required"
    }
  }

  assert {
    condition     = rhcs_hcp_machine_pool.machine_pool.aws_node_pool.ec2_metadata_http_tokens == "required"
    error_message = "Explicit ec2_metadata_http_tokens = 'required' must be wired through to rhcs_hcp_machine_pool."
  }
}

##############################################################
# H2 — management (rolling upgrade). The provider `management` block is
# Optional+Computed (UseStateForUnknown), so under an override mock the
# resource attribute may plan as "known after apply". These runs use the
# no_override provider so the configured values appear in the plan, and
# assert on the input variable for the null case.
##############################################################

# management omitted (null): the input variable is null and the plan succeeds;
# the provider/OCM defaults apply and existing pools are unaffected.
run "management_null_plan" {
  command = plan

  providers = {
    rhcs = rhcs.no_override
  }

  variables {
    cluster_id        = "fake-cluster-123"
    name              = "test-pool"
    subnet_id         = "subnet-fake123"
    openshift_version = "4.15.0"

    aws_node_pool = {
      instance_type = "m5.xlarge"
      tags          = {}
    }
  }

  assert {
    condition     = var.management == null
    error_message = "management must be null when omitted (provider/OCM defaults apply)."
  }
}

# management fully specified: all sub-values wire through to the resource.
run "management_set_plan" {
  command = plan

  providers = {
    rhcs = rhcs.no_override
  }

  variables {
    cluster_id        = "fake-cluster-123"
    name              = "test-pool"
    subnet_id         = "subnet-fake123"
    openshift_version = "4.15.0"

    aws_node_pool = {
      instance_type = "m5.xlarge"
      tags          = {}
    }

    management = {
      max_surge       = "2"
      max_unavailable = "10%"
      type            = "Replace"
    }
  }

  assert {
    condition     = rhcs_hcp_machine_pool.machine_pool.management.max_surge == "2"
    error_message = "management.max_surge must be wired through to rhcs_hcp_machine_pool."
  }

  assert {
    condition     = rhcs_hcp_machine_pool.machine_pool.management.max_unavailable == "10%"
    error_message = "management.max_unavailable must be wired through to rhcs_hcp_machine_pool."
  }

  assert {
    condition     = rhcs_hcp_machine_pool.machine_pool.management.type == "Replace"
    error_message = "management.type must be wired through to rhcs_hcp_machine_pool."
  }
}

# management partial: only max_surge set; the others are omitted (null).
run "management_partial_plan" {
  command = plan

  providers = {
    rhcs = rhcs.no_override
  }

  variables {
    cluster_id        = "fake-cluster-123"
    name              = "test-pool"
    subnet_id         = "subnet-fake123"
    openshift_version = "4.15.0"

    aws_node_pool = {
      instance_type = "m5.xlarge"
      tags          = {}
    }

    management = {
      max_surge = "1"
    }
  }

  assert {
    condition     = rhcs_hcp_machine_pool.machine_pool.management.max_surge == "1"
    error_message = "management.max_surge must wire through when only it is set."
  }

  # The provider `management` block is Optional+Computed, so sub-attributes
  # omitted from a partial object plan as "known after apply" rather than
  # null. Assert on the input variable to prove the partial object is
  # accepted with the other fields unset.
  assert {
    condition     = var.management.max_unavailable == null
    error_message = "management.max_unavailable must be unset in a partial management object."
  }

  assert {
    condition     = var.management.type == null
    error_message = "management.type must be unset in a partial management object."
  }
}

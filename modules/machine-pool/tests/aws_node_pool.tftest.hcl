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

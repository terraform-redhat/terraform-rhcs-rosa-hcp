// Copyright Red Hat
// SPDX-License-Identifier: Apache-2.0

mock_provider "rhcs" {
  alias = "default"
}

# Valid: single contact plans successfully.
run "valid_single_contact_plan" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id = "fake-cluster-123"
    contacts   = ["user-one"]
  }

  assert {
    condition     = rhcs_cluster_notification_contacts.this.cluster_id == "fake-cluster-123"
    error_message = "Expected cluster_id to be passed through."
  }

  assert {
    condition     = contains(rhcs_cluster_notification_contacts.this.contacts, "user-one")
    error_message = "Expected contacts to include user-one."
  }
}

# Valid: multiple contacts plan successfully.
run "valid_multiple_contacts_plan" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id = "fake-cluster-456"
    contacts   = ["user-one", "user-two", "user-three"]
  }

  assert {
    condition     = length(rhcs_cluster_notification_contacts.this.contacts) == 3
    error_message = "Expected three contacts in the planned resource."
  }
}

# Empty contacts set — fails validation (at least one required).
run "empty_contacts_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id = "fake-cluster-123"
    contacts   = []
  }

  expect_failures = [
    var.contacts,
  ]
}

# Whitespace-only contact — fails validation (non-empty required).
run "whitespace_contact_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id = "fake-cluster-123"
    contacts   = ["   "]
  }

  expect_failures = [
    var.contacts,
  ]
}

# Empty-string contact — fails validation (non-empty required).
run "empty_string_contact_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id = "fake-cluster-123"
    contacts   = ["valid-user", ""]
  }

  expect_failures = [
    var.contacts,
  ]
}

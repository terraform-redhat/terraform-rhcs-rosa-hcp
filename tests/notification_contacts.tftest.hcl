// Copyright Red Hat
// SPDX-License-Identifier: Apache-2.0

// Root-module validation tests for the notification_contacts variable.
// Child-module tests live in modules/notification-contacts/tests/.

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
  openshift_version      = "4.15.0"
  aws_subnet_ids         = ["subnet-fake12345"]
  aws_availability_zones = ["us-east-1a"]
  create_oidc            = true
  create_operator_roles  = false
  create_account_roles   = false
}

# Empty set — fails validation (at least one contact required).
run "root_empty_notification_contacts_fails" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.default
    null = null.default
  }

  variables {
    notification_contacts = []
  }

  expect_failures = [
    var.notification_contacts,
  ]
}

# Whitespace-only contact — fails validation (non-empty required).
run "root_whitespace_notification_contact_fails" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.default
    null = null.default
  }

  variables {
    notification_contacts = ["   "]
  }

  expect_failures = [
    var.notification_contacts,
  ]
}

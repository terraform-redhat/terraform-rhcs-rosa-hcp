# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  alias = "default"
}

mock_provider "rhcs" {
  alias           = "prod"
  override_during = plan

  mock_data "rhcs_info" {
    defaults = {
      organization_external_id = "orgext123"
      ocm_api                  = "https://api.openshift.com"
      ocm_aws_account_id       = "000000000000"
    }
  }

  mock_data "rhcs_hcp_policies" {
    defaults = {
      ocm_role_policies = {
        sts_ocm_trust_policy                 = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Principal\":{\"AWS\":\"arn:aws:iam::000000000000:root\"}}]}"
        sts_ocm_permission_policy            = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"iam:GetRole\"],\"Resource\":\"*\"}]}"
        sts_ocm_admin_permission_policy      = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"iam:*\"],\"Resource\":\"*\"}]}"
        sts_ocm_no_console_permission_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"iam:GetRole\",\"Resource\":\"*\"}]}"
      }
    }
  }

  mock_resource "rhcs_rosa_ocm_role_link" {
    defaults = {
      id = "ocm-link-id"
    }
  }
}

mock_provider "rhcs" {
  alias           = "stage"
  override_during = plan

  mock_data "rhcs_info" {
    defaults = {
      organization_external_id = "orgext123"
      ocm_api                  = "https://api.stage.openshift.com"
      ocm_aws_account_id       = "000000000000"
    }
  }

  mock_data "rhcs_hcp_policies" {
    defaults = {
      ocm_role_policies = {
        sts_ocm_trust_policy                 = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Principal\":{\"AWS\":\"arn:aws:iam::000000000000:root\"}}]}"
        sts_ocm_permission_policy            = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"iam:GetRole\"],\"Resource\":\"*\"}]}"
        sts_ocm_admin_permission_policy      = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"iam:*\"],\"Resource\":\"*\"}]}"
        sts_ocm_no_console_permission_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"iam:GetRole\",\"Resource\":\"*\"}]}"
      }
    }
  }

  mock_resource "rhcs_rosa_ocm_role_link" {
    defaults = {
      id = "ocm-link-id"
    }
  }
}

mock_provider "rhcs" {
  alias           = "int"
  override_during = plan

  mock_data "rhcs_info" {
    defaults = {
      organization_external_id = "orgext123"
      ocm_api                  = "https://api.integration.openshift.com"
      ocm_aws_account_id       = "000000000000"
    }
  }

  mock_data "rhcs_hcp_policies" {
    defaults = {
      ocm_role_policies = {
        sts_ocm_trust_policy                 = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Principal\":{\"AWS\":\"arn:aws:iam::000000000000:root\"}}]}"
        sts_ocm_permission_policy            = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"iam:GetRole\"],\"Resource\":\"*\"}]}"
        sts_ocm_admin_permission_policy      = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"iam:*\"],\"Resource\":\"*\"}]}"
        sts_ocm_no_console_permission_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"iam:GetRole\",\"Resource\":\"*\"}]}"
      }
    }
  }

  mock_resource "rhcs_rosa_ocm_role_link" {
    defaults = {
      id = "ocm-link-id"
    }
  }
}

# Standard OCM role (default profile) -- plans successfully with correct tags, naming, and link.
run "standard_ocm_role_plan" {
  command = plan

  providers = {
    rhcs = rhcs.prod
    aws  = aws.default
  }

  variables {
    ocm_role_prefix = "ManagedOpenShift"
  }

  assert {
    condition     = aws_iam_role.ocm_role.name == "ManagedOpenShift-OCM-Role-orgext123"
    error_message = "Expected OCM role name to follow the ROSA CLI naming pattern."
  }

  assert {
    condition     = aws_iam_role.ocm_role.tags["red-hat-managed"] == "true"
    error_message = "Expected red-hat-managed tag to be true."
  }

  assert {
    condition     = aws_iam_role.ocm_role.tags["rosa_role_prefix"] == "ManagedOpenShift"
    error_message = "Expected rosa_role_prefix tag to match the prefix variable."
  }

  assert {
    condition     = aws_iam_role.ocm_role.tags["rosa_role_type"] == "OCM"
    error_message = "Expected rosa_role_type tag to be OCM."
  }

  assert {
    condition     = aws_iam_role.ocm_role.tags["rosa_environment"] == "production"
    error_message = "Expected rosa_environment tag to default to production."
  }

  assert {
    condition     = !contains(keys(aws_iam_role.ocm_role.tags), "rosa_admin_role")
    error_message = "Standard role must not have rosa_admin_role tag."
  }

  assert {
    condition     = !contains(keys(aws_iam_role.ocm_role.tags), "rosa_no_console_role")
    error_message = "Standard role must not have rosa_no_console_role tag."
  }

  assert {
    condition     = length(aws_iam_policy.standard_permission_policy) == 1
    error_message = "Standard role must create the standard permission policy."
  }

  assert {
    condition     = length(aws_iam_policy.ocm_admin_permission_policy) == 0
    error_message = "Standard role must not create the admin permission policy."
  }

  assert {
    condition     = length(aws_iam_policy.ocm_no_console_permission_policy) == 0
    error_message = "Standard role must not create the no-console permission policy."
  }

  assert {
    condition     = rhcs_rosa_ocm_role_link.this[0].id == "ocm-link-id"
    error_message = "Expected the module to create the OCM-side link resource."
  }
}

# Admin OCM role -- plans with standard + admin policies.
run "admin_ocm_role_plan" {
  command = plan

  providers = {
    rhcs = rhcs.prod
    aws  = aws.default
  }

  variables {
    ocm_role_prefix = "ManagedOpenShift"
    profile         = "admin"
  }

  assert {
    condition     = aws_iam_role.ocm_role.tags["rosa_admin_role"] == "true"
    error_message = "Admin role must have rosa_admin_role=true tag."
  }

  assert {
    condition     = !contains(keys(aws_iam_role.ocm_role.tags), "rosa_no_console_role")
    error_message = "Admin role must not have rosa_no_console_role tag."
  }

  assert {
    condition     = length(aws_iam_policy.standard_permission_policy) == 1
    error_message = "Admin role must keep the standard permission policy."
  }

  assert {
    condition     = length(aws_iam_policy.ocm_admin_permission_policy) == 1
    error_message = "Admin role must create exactly one admin permission policy."
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.standard_permission_policy_attachment) == 1
    error_message = "Admin role must attach the standard permission policy."
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.ocm_admin_permission_policy_attachment) == 1
    error_message = "Admin role must attach the admin permission policy."
  }
}

# No-console OCM role -- plans with no-console tag and policy only.
run "no_console_ocm_role_plan" {
  command = plan

  providers = {
    rhcs = rhcs.prod
    aws  = aws.default
  }

  variables {
    ocm_role_prefix = "ManagedOpenShift"
    profile         = "no-console"
  }

  assert {
    condition     = aws_iam_role.ocm_role.tags["rosa_no_console_role"] == "true"
    error_message = "No-console role must have rosa_no_console_role=true tag."
  }

  assert {
    condition     = !contains(keys(aws_iam_role.ocm_role.tags), "rosa_admin_role")
    error_message = "No-console role must not have rosa_admin_role tag."
  }

  assert {
    condition     = length(aws_iam_policy.standard_permission_policy) == 0
    error_message = "No-console role must not create the standard permission policy."
  }

  assert {
    condition     = length(aws_iam_policy.ocm_admin_permission_policy) == 0
    error_message = "No-console role must not create the admin permission policy."
  }

  assert {
    condition     = length(aws_iam_policy.ocm_no_console_permission_policy) == 1
    error_message = "No-console role must create the no-console permission policy."
  }
}

# Derived environment tag from OCM API.
run "staging_environment_plan" {
  command = plan

  providers = {
    rhcs = rhcs.stage
    aws  = aws.default
  }

  variables {
    ocm_role_prefix = "MyPrefix"
  }

  assert {
    condition     = aws_iam_role.ocm_role.tags["rosa_environment"] == "staging"
    error_message = "Expected rosa_environment tag to be derived as staging."
  }

  assert {
    condition     = aws_iam_role.ocm_role.tags["rosa_role_prefix"] == "MyPrefix"
    error_message = "Expected rosa_role_prefix tag to match the provided prefix."
  }
}

# Derived environment tag from OCM API (integration).
run "integration_environment_plan" {
  command = plan

  providers = {
    rhcs = rhcs.int
    aws  = aws.default
  }

  variables {
    ocm_role_prefix = "MyPrefix"
  }

  assert {
    condition     = aws_iam_role.ocm_role.tags["rosa_environment"] == "integration"
    error_message = "Expected rosa_environment tag to be derived as integration."
  }
}

# Invalid profile value fails validation.
run "invalid_profile_fails" {
  command = plan

  providers = {
    rhcs = rhcs.prod
    aws  = aws.default
  }

  variables {
    ocm_role_prefix = "ManagedOpenShift"
    profile         = "invalid"
  }

  expect_failures = [
    var.profile,
  ]
}

# Prefix exceeding 32 characters fails validation.
run "prefix_too_long_fails" {
  command = plan

  providers = {
    rhcs = rhcs.prod
    aws  = aws.default
  }

  variables {
    ocm_role_prefix = "abcdefghijklmnopqrstuvwxyz1234567"
  }

  expect_failures = [
    var.ocm_role_prefix,
  ]
}

# Prefix with invalid characters fails validation.
run "prefix_invalid_chars_fails" {
  command = plan

  providers = {
    rhcs = rhcs.prod
    aws  = aws.default
  }

  variables {
    ocm_role_prefix = "invalid prefix!"
  }

  expect_failures = [
    var.ocm_role_prefix,
  ]
}

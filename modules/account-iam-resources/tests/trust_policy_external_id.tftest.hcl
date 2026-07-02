// Copyright Red Hat
// SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  alias = "default"

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn  = "arn:aws:iam::123456789012:role/mock"
      id   = "mock-role-id"
      name = "mock-role"
    }
  }

  mock_resource "aws_iam_role_policy_attachment" {
    defaults = {
      id = "mock-attachment-id"
    }
  }
}

mock_provider "rhcs" {
  alias = "default"

  mock_data "rhcs_hcp_policies" {
    defaults = {
      account_role_policies = {
        sts_support_rh_sre_role = "arn:aws:iam::999999999999:role/RH-SRE-Support"
      }
    }
  }

  mock_data "rhcs_info" {
    defaults = {
      ocm_aws_account_id = "999999999999"
    }
  }
}

mock_provider "time" {
  alias = "default"

  mock_resource "time_sleep" {
    defaults = {
      id = "mock-sleep"
    }
  }
}

mock_provider "random" {
  alias = "default"
}

variables {
  account_role_prefix = "tf-test-acc"
}

run "null_external_id_omits_condition" {
  command = plan

  providers = {
    aws    = aws.default
    rhcs   = rhcs.default
    time   = time.default
    random = random.default
  }

  variables {
    trust_policy_external_id = null
  }

  assert {
    condition     = !strcontains(aws_iam_role.account_role[0].assume_role_policy, "sts:ExternalId")
    error_message = "Installer trust policy must not include sts:ExternalId when trust_policy_external_id is null."
  }

  assert {
    condition     = !strcontains(aws_iam_role.account_role[1].assume_role_policy, "sts:ExternalId")
    error_message = "Support trust policy must not include sts:ExternalId when trust_policy_external_id is null."
  }
}

run "empty_external_id_rejected" {
  command = plan

  providers = {
    aws    = aws.default
    rhcs   = rhcs.default
    time   = time.default
    random = random.default
  }

  variables {
    trust_policy_external_id = ""
  }

  expect_failures = [
    var.trust_policy_external_id,
  ]
}

run "whitespace_external_id_rejected" {
  command = plan

  providers = {
    aws    = aws.default
    rhcs   = rhcs.default
    time   = time.default
    random = random.default
  }

  variables {
    trust_policy_external_id = "   "
  }

  expect_failures = [
    var.trust_policy_external_id,
  ]
}

run "non_empty_external_id_adds_condition_to_installer_and_support" {
  command = plan

  providers = {
    aws    = aws.default
    rhcs   = rhcs.default
    time   = time.default
    random = random.default
  }

  variables {
    trust_policy_external_id = "test-external-id-12345"
  }

  assert {
    condition = strcontains(
      aws_iam_role.account_role[0].assume_role_policy,
      "test-external-id-12345",
    )
    error_message = "Installer trust policy must include the configured external ID."
  }

  assert {
    condition = strcontains(
      aws_iam_role.account_role[1].assume_role_policy,
      "test-external-id-12345",
    )
    error_message = "Support trust policy must include the configured external ID."
  }

  assert {
    condition = strcontains(
      aws_iam_role.account_role[0].assume_role_policy,
      "sts:ExternalId",
    )
    error_message = "Installer trust policy must include sts:ExternalId condition key."
  }

  assert {
    condition = strcontains(
      aws_iam_role.account_role[1].assume_role_policy,
      "sts:ExternalId",
    )
    error_message = "Support trust policy must include sts:ExternalId condition key."
  }
}

run "worker_never_includes_external_id" {
  command = plan

  providers = {
    aws    = aws.default
    rhcs   = rhcs.default
    time   = time.default
    random = random.default
  }

  variables {
    trust_policy_external_id = "test-external-id-12345"
  }

  assert {
    condition     = !strcontains(aws_iam_role.account_role[2].assume_role_policy, "sts:ExternalId")
    error_message = "Worker trust policy must never include sts:ExternalId."
  }

  assert {
    condition     = strcontains(aws_iam_role.account_role[2].assume_role_policy, "ec2.amazonaws.com")
    error_message = "Worker role trust policy must trust ec2.amazonaws.com."
  }

  assert {
    condition     = length(aws_iam_role.account_role) == 3
    error_message = "account_iam_resources must create Installer, Support, and Worker roles."
  }
}

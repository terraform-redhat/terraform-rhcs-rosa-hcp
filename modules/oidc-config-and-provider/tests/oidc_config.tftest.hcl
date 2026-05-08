// Copyright Red Hat
// SPDX-License-Identifier: Apache-2.0

mock_provider "rhcs" {
  alias = "default"
}

mock_provider "aws" {
  alias = "default"
}

mock_provider "time" {
  alias = "default"
}

mock_provider "null" {
  alias = "default"
}

# oidc_prefix variable validation: maximum 16 characters.
run "oidc_prefix_too_long_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
    aws  = aws.default
    time = time.default
    null = null.default
  }

  variables {
    managed     = true
    oidc_prefix = "abcdefghijklmnopq"
  }

  expect_failures = [
    var.oidc_prefix,
  ]
}

# oidc_prefix variable validation: pattern (must start with lowercase letter, etc.).
run "oidc_prefix_invalid_pattern_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
    aws  = aws.default
    time = time.default
    null = null.default
  }

  variables {
    managed     = true
    oidc_prefix = "InvalidPrefix"
  }

  expect_failures = [
    var.oidc_prefix,
  ]
}

# Module precondition: managed OIDC must not set installer_role_arn.
run "managed_with_installer_role_arn_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
    aws  = aws.default
    time = time.default
    null = null.default
  }

  variables {
    managed            = true
    installer_role_arn = "arn:aws:iam::123456789012:role/rosa-installer"
  }

  expect_failures = [
    null_resource.unmanaged_vars_validation,
  ]
}

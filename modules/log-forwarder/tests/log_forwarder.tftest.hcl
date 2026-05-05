// Copyright Red Hat
// SPDX-License-Identifier: Apache-2.0

mock_provider "rhcs" {
  alias = "default"
}

# Both s3 and cloudwatch set — fails module precondition (matches provider ExactlyOneOf).
run "both_s3_and_cloudwatch_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id = "fake-cluster-123"

    s3 = {
      bucket_name = "bucket-a"
    }

    cloudwatch = {
      log_group_name            = "/aws/rosa/fake"
      log_distribution_role_arn = "arn:aws:iam::123456789012:role/LogDist"
    }

    applications = ["my-app"]
  }

  expect_failures = [
    rhcs_log_forwarder.this,
  ]
}

# Neither destination — fails module precondition.
run "neither_s3_nor_cloudwatch_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id   = "fake-cluster-123"
    s3           = null
    cloudwatch   = null
    applications = ["my-app"]
  }

  expect_failures = [
    rhcs_log_forwarder.this,
  ]
}

# Exactly one destination but no applications and no groups — fails module precondition
# (matches provider config validator).
run "empty_applications_and_groups_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id = "fake-cluster-123"

    s3 = {
      bucket_name = "bucket-a"
    }

    applications = []
    groups       = []
  }

  expect_failures = [
    rhcs_log_forwarder.this,
  ]
}

# Exactly one destination but no applications and no groups — fails module precondition
# (matches provider config validator).
run "empty_string_applications_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id = "fake-cluster-123"

    s3 = {
      bucket_name = "bucket-a"
    }

    applications = [""]
  }

  expect_failures = [
    rhcs_log_forwarder.this,
  ]
}

run "whitespace_applications_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id = "fake-cluster-123"

    s3 = {
      bucket_name = "bucket-a"
    }

    applications = ["   "]
  }

  expect_failures = [
    rhcs_log_forwarder.this,
  ]
}

run "empty_group_id_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id = "fake-cluster-123"

    cloudwatch = {
      log_group_name            = "/aws/rosa/fake"
      log_distribution_role_arn = "arn:aws:iam::123456789012:role/LogDist"
    }

    groups = [
      { id = "", version = "1.0" }
    ]
  }

  expect_failures = [
    rhcs_log_forwarder.this,
  ]
}

run "whitespace_group_id_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id = "fake-cluster-123"

    cloudwatch = {
      log_group_name            = "/aws/rosa/fake"
      log_distribution_role_arn = "arn:aws:iam::123456789012:role/LogDist"
    }

    groups = [
      { id = "   ", version = "1.0" }
    ]
  }

  expect_failures = [
    rhcs_log_forwarder.this,
  ]
}

run "null_applications_and_null_groups_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id = "fake-cluster-123"

    s3 = {
      bucket_name = "bucket-a"
    }

    applications = null
    groups       = null
  }

  expect_failures = [
    rhcs_log_forwarder.this,
  ]
}

# Valid: S3 + applications only.
run "valid_s3_and_applications_plan" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id = "fake-cluster-123"

    s3 = {
      bucket_name   = "valid-bucket"
      bucket_prefix = "prefix/"
    }

    applications = ["openshift-api"]
  }

  assert {
    condition     = rhcs_log_forwarder.this.cluster == "fake-cluster-123"
    error_message = "Expected cluster id to be passed through to rhcs_log_forwarder."
  }

  assert {
    condition     = rhcs_log_forwarder.this.s3.bucket_name == "valid-bucket"
    error_message = "Expected S3 bucket_name in planned resource."
  }

  assert {
    condition     = rhcs_log_forwarder.this.s3.bucket_prefix == "prefix/"
    error_message = "Expected S3 bucket_prefix in planned resource."
  }

  assert {
    condition     = contains(rhcs_log_forwarder.this.applications, "openshift-api")
    error_message = "Expected applications list to include openshift-api."
  }
}

# Valid: CloudWatch + groups (no applications).
run "valid_cloudwatch_and_groups_plan" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id = "fake-cluster-456"

    cloudwatch = {
      log_group_name            = "/rosa/hcp/logs"
      log_distribution_role_arn = "arn:aws:iam::123456789012:role/RosaLogForward"
    }

    groups = [
      { id = "audit", version = "1.0" }
    ]
  }

  assert {
    condition     = rhcs_log_forwarder.this.cloudwatch.log_group_name == "/rosa/hcp/logs"
    error_message = "Expected CloudWatch log_group_name in planned resource."
  }

  assert {
    condition     = length(rhcs_log_forwarder.this.groups) == 1
    error_message = "Expected one log forwarder group."
  }

  assert {
    condition     = rhcs_log_forwarder.this.groups[0].id == "audit"
    error_message = "Expected group id audit."
  }
}

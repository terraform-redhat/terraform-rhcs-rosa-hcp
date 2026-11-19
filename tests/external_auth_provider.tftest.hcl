// Copyright Red Hat
// SPDX-License-Identifier: Apache-2.0

// Root-module wiring tests for the external_auth_provider feature.
// Child-module tests live in modules/external-auth-provider/tests/.
// The root proxy sensitivity runs live in tests/proxy_sensitivity.tftest.hcl.

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
  openshift_version      = "4.15.0"
  aws_subnet_ids         = ["subnet-fake12345"]
  aws_availability_zones = ["us-east-1a"]
  create_oidc            = false
  oidc_config_id         = "00000000000000000000000000000000"
  create_operator_roles  = false
  create_account_roles   = false
}

# Default configuration: nothing external-auth related is set, so the feature is
# off and no rhcs_external_auth_provider resource enters the graph.
run "root_external_auth_disabled_by_default" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.default
    null = null.default
  }

  assert {
    condition     = var.external_auth_provider == null
    error_message = "external_auth_provider must default to null so existing consumers are unaffected."
  }

  assert {
    condition     = var.external_auth_provider_console_client_secret == null
    error_message = "external_auth_provider_console_client_secret must default to null."
  }

  assert {
    condition     = length(module.rhcs_hcp_external_auth_provider) == 0
    error_message = "Expected zero external-auth-provider module instances when external_auth_provider is null."
  }
}

# Feature enabled: the prerequisite cluster flag is true and the provider object
# is supplied, so exactly one module instance is created.
run "root_external_auth_enabled_plan" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.default
    null = null.default
  }

  variables {
    external_auth_providers_enabled = true

    external_auth_provider = {
      name                         = "fake-external-auth"
      issuer_url                   = "https://issuer.example.com/realms/rosa"
      issuer_audiences             = ["fake-console-client"]
      claim_mapping_username_claim = "email"
      console_client_id            = "fake-console-client"
      console_extra_scopes         = ["profile"]
    }

    external_auth_provider_console_client_secret = "fake-console-secret"
  }

  assert {
    condition     = length(module.rhcs_hcp_external_auth_provider) == 1
    error_message = "Expected one external-auth-provider module instance when external_auth_provider is set."
  }

  assert {
    condition     = issensitive(var.external_auth_provider_console_client_secret)
    error_message = "external_auth_provider_console_client_secret must be a sensitive variable."
  }

  assert {
    condition     = nonsensitive(var.external_auth_provider_console_client_secret) == "fake-console-secret"
    error_message = "Expected the console client secret to carry the configured value."
  }
}

# Prerequisite not set: external_auth_providers_enabled defaults to null.
run "root_external_auth_without_flag_fails" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.default
    null = null.default
  }

  variables {
    external_auth_provider = {
      name             = "fake-external-auth"
      issuer_url       = "https://issuer.example.com/realms/rosa"
      issuer_audiences = ["fake-audience-1"]
    }
  }

  expect_failures = [
    null_resource.validations,
  ]
}

# Prerequisite explicitly false — external auth cannot be turned on afterwards.
run "root_external_auth_flag_false_fails" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.default
    null = null.default
  }

  variables {
    external_auth_providers_enabled = false

    external_auth_provider = {
      name             = "fake-external-auth"
      issuer_url       = "https://issuer.example.com/realms/rosa"
      issuer_audiences = ["fake-audience-1"]
    }
  }

  expect_failures = [
    null_resource.validations,
  ]
}

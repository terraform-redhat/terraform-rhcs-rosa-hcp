// Copyright Red Hat
// SPDX-License-Identifier: Apache-2.0

// Root-module wiring tests for the external_auth_provider feature and for the
// inputs that terraform-redhat/rhcs 1.7.13 marks sensitive.
// Child-module tests live in modules/external-auth-provider/tests/.

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

# terraform-redhat/rhcs 1.7.13 marks the proxy credentials and the additional
# trust bundle sensitive. The matching root inputs are sensitive too, and the
# plan still succeeds end to end with them set. issensitive() reports the
# sensitivity directly, so removing any `sensitive = true` fails this run.
run "root_proxy_inputs_are_sensitive_and_plan" {
  command = plan

  providers = {
    aws  = aws.default
    rhcs = rhcs.default
    null = null.default
  }

  variables {
    http_proxy              = "http://proxy.example.com:3128"
    https_proxy             = "https://proxy.example.com:3129"
    no_proxy                = "localhost,.svc"
    additional_trust_bundle = "-----BEGIN CERTIFICATE-----\nfake\n-----END CERTIFICATE-----\n"
  }

  assert {
    condition     = issensitive(var.http_proxy)
    error_message = "http_proxy must be a sensitive variable."
  }

  assert {
    condition     = nonsensitive(var.http_proxy) == "http://proxy.example.com:3128"
    error_message = "Expected http_proxy to carry the configured value."
  }

  assert {
    condition     = issensitive(var.https_proxy)
    error_message = "https_proxy must be a sensitive variable."
  }

  assert {
    condition     = nonsensitive(var.https_proxy) == "https://proxy.example.com:3129"
    error_message = "Expected https_proxy to carry the configured value."
  }

  assert {
    condition     = issensitive(var.additional_trust_bundle)
    error_message = "additional_trust_bundle must be a sensitive variable."
  }

  assert {
    condition     = nonsensitive(var.additional_trust_bundle) == "-----BEGIN CERTIFICATE-----\nfake\n-----END CERTIFICATE-----\n"
    error_message = "Expected additional_trust_bundle to carry the configured value."
  }

  # The no_proxy variable stays non-sensitive, matching
  # provider/proxy/proxy_resource.go. Marking the other three inputs sensitive
  # does mark the whole planned proxy object, no_proxy included; see
  # modules/rosa-cluster-hcp/tests/proxy_sensitivity.tftest.hcl.
  assert {
    condition     = !issensitive(var.no_proxy) && var.no_proxy == "localhost,.svc"
    error_message = "Expected no_proxy to stay a plain, non-sensitive root variable."
  }
}

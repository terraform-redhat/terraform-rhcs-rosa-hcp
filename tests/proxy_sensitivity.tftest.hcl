// Copyright Red Hat
// SPDX-License-Identifier: Apache-2.0

// Root-module regression guards for the cluster proxy inputs. These runs use
// mock_provider, so they do not exercise provider behavior: they assert this
// module's own `sensitive = true` on the inputs that map to the
// rhcs_cluster_rosa_hcp proxy attributes marked sensitive in the resource
// schema at terraform-redhat/rhcs 1.7.13. They therefore fail if someone
// deletes a `sensitive = true`, and they pass against earlier provider
// releases as well. Kept separate from the feature suites so the runs stand
// alone; the child-module view lives in
// modules/rosa-cluster-hcp/tests/proxy_sensitivity.tftest.hcl.

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

# The root inputs that map to the proxy credentials and the additional trust
# bundle carry `sensitive = true`, matching the rhcs_cluster_rosa_hcp resource
# schema at terraform-redhat/rhcs 1.7.13, and the plan still succeeds end to
# end with them set. issensitive() reports the module's own sensitivity
# directly, so removing any `sensitive = true` fails this run.
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

  # The no_proxy variable stays non-sensitive, matching the
  # rhcs_cluster_rosa_hcp resource schema at terraform-redhat/rhcs 1.7.13.
  # The planned proxy object is still marked as a whole, no_proxy included,
  # whenever any proxy input produces a proxy block, because the cluster
  # submodule builds that object with a conditional whose condition reads the
  # sensitive proxy variables; see
  # modules/rosa-cluster-hcp/tests/proxy_sensitivity.tftest.hcl.
  assert {
    condition     = !issensitive(var.no_proxy) && var.no_proxy == "localhost,.svc"
    error_message = "Expected no_proxy to stay a plain, non-sensitive root variable."
  }
}

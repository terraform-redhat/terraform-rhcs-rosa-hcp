// Copyright Red Hat
// SPDX-License-Identifier: Apache-2.0

// Regression guards for the proxy inputs. The rhcs_cluster_rosa_hcp resource
// schema at terraform-redhat/rhcs 1.7.13 marks proxy.http_proxy,
// proxy.https_proxy and proxy.additional_trust_bundle sensitive, and leaves
// proxy.no_proxy plain. These runs use mock_provider, so they do not exercise
// provider behavior: they assert this module's own `sensitive = true` on the
// matching inputs and that each value still reaches the corresponding
// rhcs_cluster_rosa_hcp proxy attribute. issensitive() reports the module's
// own sensitivity directly, so deleting a `sensitive = true` fails this file,
// while the runs pass against earlier provider releases as well.
//
// The var.no_proxy input itself stays non-sensitive, but main.tf builds the
// proxy argument with a conditional, and Terraform adds the sensitivity of a
// conditional's condition to its result. That condition reads the three
// sensitive proxy variables, which keep their sensitivity mark even while
// null, so every planned proxy object is sensitive as a whole, no_proxy
// included, and that holds even when only no_proxy is set. That is why the
// planned proxy.no_proxy below needs nonsensitive().
//
// Kept separate from rosa_cluster_hcp.tftest.hcl so the runs stand alone.

mock_provider "aws" {
  alias = "proxy"

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
}

mock_provider "rhcs" {
  alias = "proxy"
}

variables {
  cluster_name           = "proxy-cluster"
  openshift_version      = "4.15.0"
  oidc_config_id         = "00000000000000000000000000000000"
  operator_role_prefix   = "test-operator-prefix"
  account_role_prefix    = "test-account-prefix"
  aws_subnet_ids         = ["subnet-fake12345"]
  aws_availability_zones = ["us-east-1a"]
  aws_account_id         = "123456789012"
  aws_account_arn        = "arn:aws:iam::123456789012:root"
  aws_region             = "us-east-1"
}

run "proxy_inputs_are_sensitive_and_propagate" {
  command = plan

  providers = {
    aws  = aws.proxy
    rhcs = rhcs.proxy
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
  # see the file header.
  assert {
    condition     = !issensitive(var.no_proxy) && var.no_proxy == "localhost,.svc"
    error_message = "Expected no_proxy to stay a plain, non-sensitive variable."
  }

  assert {
    condition     = nonsensitive(rhcs_cluster_rosa_hcp.rosa_hcp_cluster.proxy.http_proxy) == "http://proxy.example.com:3128"
    error_message = "Expected http_proxy to reach the cluster proxy block."
  }

  assert {
    condition     = nonsensitive(rhcs_cluster_rosa_hcp.rosa_hcp_cluster.proxy.https_proxy) == "https://proxy.example.com:3129"
    error_message = "Expected https_proxy to reach the cluster proxy block."
  }

  assert {
    condition     = nonsensitive(rhcs_cluster_rosa_hcp.rosa_hcp_cluster.proxy.additional_trust_bundle) == "-----BEGIN CERTIFICATE-----\nfake\n-----END CERTIFICATE-----\n"
    error_message = "Expected additional_trust_bundle to reach the cluster proxy block."
  }

  assert {
    condition     = nonsensitive(rhcs_cluster_rosa_hcp.rosa_hcp_cluster.proxy.no_proxy) == "localhost,.svc"
    error_message = "Expected no_proxy to reach the cluster proxy block."
  }
}

run "no_proxy_block_when_all_proxy_inputs_null" {
  command = plan

  providers = {
    aws  = aws.proxy
    rhcs = rhcs.proxy
  }

  assert {
    condition     = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.proxy == null
    error_message = "Expected no proxy block when every proxy input is null."
  }
}

// Copyright Red Hat
// SPDX-License-Identifier: Apache-2.0

# The Karpenter role is opt-in and appended after the 8 base operator roles so the
# indexes used by the shared VPC attachments never change.

mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = {
      dns_suffix         = "amazonaws.com"
      id                 = "aws"
      partition          = "aws"
      reverse_dns_prefix = "amazonaws.com"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }
}

mock_provider "time" {}

variables {
  operator_role_prefix = "test-operator"
  oidc_endpoint_url    = "oidc.example.com/abc123"
}

run "karpenter_role_not_created_by_default" {
  command = plan

  assert {
    condition     = length(aws_iam_role.operator_role) == 8
    error_message = "Only the 8 base operator roles must be created when create_karpenter_role is false."
  }

  assert {
    condition     = output.karpenter_role_arn == null
    error_message = "karpenter_role_arn must be null when create_karpenter_role is false."
  }
}

run "karpenter_role_created_when_enabled" {
  command = plan

  variables {
    create_karpenter_role = true
  }

  assert {
    condition     = length(aws_iam_role.operator_role) == 9
    error_message = "The Karpenter role must be created in addition to the 8 base operator roles when create_karpenter_role is true."
  }

  assert {
    condition     = aws_iam_role.operator_role[8].name == "test-operator-kube-system-karpenter"
    error_message = "The Karpenter role must be the last operator role and be named <prefix>-kube-system-karpenter."
  }

  assert {
    condition     = aws_iam_role_policy_attachment.operator_role_policy_attachment[8].policy_arn == "arn:aws:iam::aws:policy/service-role/ROSAKarpenterControllerPolicy"
    error_message = "The Karpenter role must use the ROSAKarpenterControllerPolicy managed policy."
  }
}

# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

resource "rhcs_external_auth_provider" "this" {
  count = var.create_external_auth_provider ? 1 : 0

  cluster          = var.cluster_id
  name             = var.name
  issuer_url       = var.issuer_url
  issuer_audiences = var.issuer_audiences

  issuer_ca                    = var.issuer_ca
  claim_mapping_groups_claim   = var.claim_mapping_groups_claim
  claim_mapping_username_claim = var.claim_mapping_username_claim
  claim_validation_rule        = var.claim_validation_rule
  console_client_id            = var.console_client_id
  console_client_secret        = var.console_client_secret
  console_extra_scopes         = var.console_extra_scopes

  # The console client rules below mirror the cross-field rules that rhcs 1.7.13
  # states in its schema and applies in ValidateConfig: they accept exactly what
  # the provider accepts, so they fail the plan earlier without tightening or
  # loosening the provider's own contract. They live here rather than in variable
  # validation because each one spans several variables. Empty strings on both
  # console client fields stay valid: that is the documented way to remove the
  # console client.
  lifecycle {
    precondition {
      condition     = (var.console_client_id == null) == (var.console_client_secret == null)
      error_message = "\"console_client_id\" and \"console_client_secret\" must be set together. Set both to empty strings to remove the console client."
    }
    precondition {
      condition     = var.console_client_id != "" ? true : var.console_client_secret == ""
      error_message = "Set both \"console_client_id\" and \"console_client_secret\" to empty strings to remove the console client."
    }
    precondition {
      condition     = var.console_extra_scopes == null ? true : (var.console_client_id != null && var.console_client_id != "")
      error_message = "\"console_extra_scopes\" applies to the console client, so it requires a \"console_client_id\" set to a non-empty value. Omit the scopes instead of passing an empty set when there is no console client."
    }
    precondition {
      condition     = (var.console_client_id == null || var.console_client_id == "") ? true : contains(var.issuer_audiences, var.console_client_id)
      error_message = "\"console_client_id\" must also appear in \"issuer_audiences\"."
    }
  }
}

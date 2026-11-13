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
}

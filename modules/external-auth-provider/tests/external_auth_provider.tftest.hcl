// Copyright Red Hat
// SPDX-License-Identifier: Apache-2.0

// Child-module tests for modules/external-auth-provider.
// Root-module wiring tests live in tests/external_auth_provider.tftest.hcl.
//
// Every check in variables.tf is a variable validation block, so a failing
// case aborts before the rhcs provider is consulted. That keeps the
// expect_failures addresses unambiguous.

mock_provider "rhcs" {
  alias = "default"
}

variables {
  cluster_id       = "fake-cluster-123"
  name             = "fake-external-auth"
  issuer_url       = "https://issuer.example.com/realms/rosa"
  issuer_audiences = ["fake-audience-1"]
}

# Valid: required attributes only. Covers the create_external_auth_provider = true branch.
run "valid_minimal_plan" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  assert {
    condition     = length(rhcs_external_auth_provider.this) == 1
    error_message = "Expected one rhcs_external_auth_provider when create_external_auth_provider is true."
  }

  assert {
    condition     = rhcs_external_auth_provider.this[0].cluster == "fake-cluster-123"
    error_message = "Expected cluster_id to be passed through to the cluster attribute."
  }

  assert {
    condition     = rhcs_external_auth_provider.this[0].name == "fake-external-auth"
    error_message = "Expected name to be passed through."
  }

  assert {
    condition     = rhcs_external_auth_provider.this[0].issuer_url == "https://issuer.example.com/realms/rosa"
    error_message = "Expected issuer_url to be passed through."
  }

  assert {
    condition     = contains(rhcs_external_auth_provider.this[0].issuer_audiences, "fake-audience-1")
    error_message = "Expected issuer_audiences to include fake-audience-1."
  }
}

# Every optional attribute is Optional + Computed in the rhcs schema, so each
# module variable must default to null and leave the API value untouched.
run "optional_attributes_default_to_null" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  assert {
    condition     = var.issuer_ca == null
    error_message = "issuer_ca must default to null so the API value is preserved."
  }

  assert {
    condition     = var.claim_mapping_groups_claim == null
    error_message = "claim_mapping_groups_claim must default to null so the API value is preserved."
  }

  assert {
    condition     = var.claim_mapping_username_claim == null
    error_message = "claim_mapping_username_claim must default to null so the API value is preserved."
  }

  assert {
    condition     = var.claim_validation_rule == null
    error_message = "claim_validation_rule must default to null so the API value is preserved."
  }

  assert {
    condition     = var.console_client_id == null
    error_message = "console_client_id must default to null so the API value is preserved."
  }

  assert {
    condition     = var.console_client_secret == null
    error_message = "console_client_secret must default to null."
  }

  assert {
    condition     = var.console_extra_scopes == null
    error_message = "console_extra_scopes must default to null so the API value is preserved."
  }

  assert {
    condition     = var.create_external_auth_provider == true
    error_message = "create_external_auth_provider must default to true."
  }
}

# Valid: every optional attribute populated, including a console client whose
# client ID is also an issuer audience (required by the provider).
run "valid_full_console_plan" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    issuer_audiences             = ["fake-audience-1", "fake-console-client"]
    issuer_ca                    = <<-EOT
      -----BEGIN CERTIFICATE-----
      MIIDITCCAgmgAwIBAgIUSyWP2pxuUZx1EdezPgOnuQ7/ZkowDQYJKoZIhvcNAQEL
      BQAwHzEdMBsGA1UEAwwUZmFrZS10ZXN0LWNhLmludmFsaWQwIBcNMjYxMTEzMTMx
      NjU1WhgPMjEyNjEwMjAxMzE2NTVaMB8xHTAbBgNVBAMMFGZha2UtdGVzdC1jYS5p
      bnZhbGlkMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzEBZcZjxwZqz
      66UY2BLfHN3ChIOJEYHY5qKjCzHAhan6nvV0n4898wOJk1KjFlWGYkDKEutNEPYF
      6ZwSX7Tdz0ffITQkI/YOfxeVhp6AXw5S0zNJQwj3jd68IzXeQ1/OtptvFTGn51gO
      B7XINOP4PF5q1rWQf60nPkBgywvmPcFnw+WiYW2/8xc7xbNdwdScBwYY/IgUaeQD
      lf82yKR2qdjRRe/IhaUbdG4gsF2t1UE1Nt63OfLYEPx9CAvnWA+BT7QVUDiBC08j
      UG1q6Iwnixp+rmVpOKfJUSjsG755ffdfgm93iJkPuza3dFm2XhGAVrQZD1fjdo1y
      FYdok10npQIDAQABo1MwUTAdBgNVHQ4EFgQUsSTxvm8KIvrKSQMjuF1aX5IqnqYw
      HwYDVR0jBBgwFoAUsSTxvm8KIvrKSQMjuF1aX5IqnqYwDwYDVR0TAQH/BAUwAwEB
      /zANBgkqhkiG9w0BAQsFAAOCAQEAnWa4du9lpP+mnQYwjhmv7N3rR1jA+wI3CxPt
      WHoxPvsxtZgqZsjZ0sH852qArkR1AK4M4Y9Px23RlxTvP6jG7vvmAZ2/QfZXalqx
      Ke0o3/FloBXC7le/BhzSNAdz/j+vBgs4nWVometVIZcvTLWXeVs0QfGV9q20Ee10
      PgleOgqZMf8wjo5lKNbf3CoZGgiFREaBiyWV/0zOcxTDH+RmT83S0caQh7NJv2lW
      zY8ucpz1Hksrxx0kaI+6YCH9+wk3iztwpkW4wKxA4xhtyFSKDWybprvm7OB2J2Ci
      qx4Uo5KfV/YInCLHVd5H9DTpjmHtg31mwIeKGW3DKU/G6ZDzlw==
      -----END CERTIFICATE-----
    EOT
    claim_mapping_groups_claim   = "groups"
    claim_mapping_username_claim = "email"
    # The third rule carries a newline in the required value: the provider's
    # SplitN check accepts it, so the module validation must accept it too.
    claim_validation_rule = [
      "sub:system:admin",
      "  iss  :  https://issuer.example.com  ",
      "email:first\nsecond",
    ]
    console_client_id     = "fake-console-client"
    console_client_secret = "fake-console-secret"
    console_extra_scopes  = ["profile"]
  }

  assert {
    condition     = rhcs_external_auth_provider.this[0].console_client_id == "fake-console-client"
    error_message = "Expected console_client_id to be passed through."
  }

  assert {
    condition     = contains(rhcs_external_auth_provider.this[0].console_extra_scopes, "profile")
    error_message = "Expected console_extra_scopes to include profile."
  }

  assert {
    condition     = rhcs_external_auth_provider.this[0].claim_mapping_groups_claim == "groups"
    error_message = "Expected claim_mapping_groups_claim to be passed through."
  }

  assert {
    condition     = length(rhcs_external_auth_provider.this[0].claim_validation_rule) == 3
    error_message = "Expected three claim validation rules."
  }

  # issensitive() reports the sensitivity directly, so removing
  # `sensitive = true` from console_client_secret fails this run.
  assert {
    condition     = issensitive(var.console_client_secret)
    error_message = "console_client_secret must be a sensitive variable."
  }

  assert {
    condition     = nonsensitive(var.console_client_secret) == "fake-console-secret"
    error_message = "Expected console_client_secret to carry the configured value."
  }

  assert {
    condition     = !issensitive(var.issuer_ca)
    error_message = "issuer_ca must not be sensitive: the rhcs 1.7.13 schema does not mark it sensitive."
  }
}

# Valid: empty string and empty list clear values rather than failing validation.
run "valid_clearing_values_plan" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    issuer_ca                    = ""
    claim_mapping_groups_claim   = ""
    claim_mapping_username_claim = ""
    claim_validation_rule        = []
    console_client_id            = ""
    console_client_secret        = ""
  }

  assert {
    condition     = rhcs_external_auth_provider.this[0].issuer_ca == ""
    error_message = "Expected an empty issuer_ca to be accepted and passed through."
  }

  assert {
    condition     = length(rhcs_external_auth_provider.this[0].claim_validation_rule) == 0
    error_message = "Expected an empty claim_validation_rule list to be accepted."
  }
}

# create_external_auth_provider = false — the count = 0 branch.
run "create_false_plan" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    create_external_auth_provider = false
  }

  assert {
    condition     = length(rhcs_external_auth_provider.this) == 0
    error_message = "Expected no rhcs_external_auth_provider when create_external_auth_provider is false."
  }

  assert {
    condition     = output.id == null
    error_message = "Expected the id output to be null when create_external_auth_provider is false."
  }
}

# cluster_id validation block.
run "blank_cluster_id_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id = "   "
  }

  expect_failures = [
    var.cluster_id,
  ]
}

# name validation block.
run "blank_name_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    name = ""
  }

  expect_failures = [
    var.name,
  ]
}

# issuer_url validation block — scheme must be https.
run "non_https_issuer_url_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    issuer_url = "http://issuer.example.com"
  }

  expect_failures = [
    var.issuer_url,
  ]
}

# issuer_url validation block — user information is rejected.
run "issuer_url_with_user_info_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    issuer_url = "https://user:pass@issuer.example.com"
  }

  expect_failures = [
    var.issuer_url,
  ]
}

# issuer_audiences size validation block — lower bound.
run "empty_issuer_audiences_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    issuer_audiences = []
  }

  expect_failures = [
    var.issuer_audiences,
  ]
}

# issuer_audiences size validation block — upper bound (eleven values).
run "too_many_issuer_audiences_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    issuer_audiences = [
      "aud-01", "aud-02", "aud-03", "aud-04", "aud-05", "aud-06",
      "aud-07", "aud-08", "aud-09", "aud-10", "aud-11",
    ]
  }

  expect_failures = [
    var.issuer_audiences,
  ]
}

# issuer_audiences non-blank validation block.
run "blank_issuer_audience_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    issuer_audiences = ["fake-audience-1", "   "]
  }

  expect_failures = [
    var.issuer_audiences,
  ]
}

# issuer_ca validation block — a file path is the common mistake.
run "issuer_ca_path_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    issuer_ca = "./ca.pem"
  }

  expect_failures = [
    var.issuer_ca,
  ]
}

# claim_mapping_groups_claim validation block.
run "blank_groups_claim_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    claim_mapping_groups_claim = "  "
  }

  expect_failures = [
    var.claim_mapping_groups_claim,
  ]
}

# claim_mapping_username_claim validation block.
run "blank_username_claim_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    claim_mapping_username_claim = "  "
  }

  expect_failures = [
    var.claim_mapping_username_claim,
  ]
}

# claim_validation_rule validation block.
run "malformed_claim_validation_rule_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    claim_validation_rule = ["noseparator"]
  }

  expect_failures = [
    var.claim_validation_rule,
  ]
}

# console_client_id validation block.
run "blank_console_client_id_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    console_client_id     = "  "
    console_client_secret = "fake-console-secret"
  }

  expect_failures = [
    var.console_client_id,
  ]
}

# console_client_secret validation block.
run "blank_console_client_secret_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    issuer_audiences      = ["fake-console-client"]
    console_client_id     = "fake-console-client"
    console_client_secret = "  "
  }

  expect_failures = [
    var.console_client_secret,
  ]
}

# console_extra_scopes validation block.
run "whitespace_console_extra_scope_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    issuer_audiences      = ["fake-console-client"]
    console_client_id     = "fake-console-client"
    console_client_secret = "fake-console-secret"
    console_extra_scopes  = ["pro file"]
  }

  expect_failures = [
    var.console_extra_scopes,
  ]
}

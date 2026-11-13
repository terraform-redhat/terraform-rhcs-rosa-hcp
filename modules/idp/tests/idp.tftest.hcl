// Copyright Red Hat
// SPDX-License-Identifier: Apache-2.0

mock_provider "rhcs" {
  alias = "default"
}

# idp_type variable validation (must be a supported provider type).
run "invalid_idp_type_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id = "fake-cluster-123"
    name       = "test-idp"
    idp_type   = "azure"
  }

  expect_failures = [
    var.idp_type,
  ]
}

# Github IDP: module precondition requires client_id when idp_type is github.
run "github_missing_client_id_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id               = "fake-cluster-123"
    name                     = "test-github"
    idp_type                 = "github"
    github_idp_client_id     = null
    github_idp_client_secret = "not-empty-secret"
  }

  expect_failures = [
    rhcs_identity_provider.github_identity_provider,
  ]
}

# Htpasswd IDP: module precondition requires htpasswd_idp_users when idp_type is htpasswd.
run "htpasswd_missing_users_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id         = "fake-cluster-123"
    name               = "test-htpasswd"
    idp_type           = "htpasswd"
    htpasswd_idp_users = null
  }

  expect_failures = [
    rhcs_identity_provider.htpasswd_identity_provider,
  ]
}

# LDAP IDP: module precondition requires ldap_idp_url.
run "ldap_missing_url_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id   = "fake-cluster-123"
    name         = "test-ldap"
    idp_type     = "ldap"
    ldap_idp_url = null
  }

  expect_failures = [
    rhcs_identity_provider.ldap_identity_provider,
  ]
}

# OpenID IDP: module precondition requires openid_idp_client_id.
run "openid_missing_client_id_fails" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id               = "fake-cluster-123"
    name                     = "test-openid"
    idp_type                 = "openid"
    openid_idp_client_id     = null
    openid_idp_client_secret = "not-empty-secret"
    openid_idp_issuer        = "https://issuer.example.com"
  }

  expect_failures = [
    rhcs_identity_provider.openid_identity_provider,
  ]
}

# Valid htpasswd plan (password meets provider rules).
run "valid_htpasswd_plan" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id = "fake-cluster-123"
    name       = "test-htpasswd-ok"
    idp_type   = "htpasswd"
    htpasswd_idp_users = [
      {
        username = "admin"
        password = "Not-a-mock-passw0rd"
      }
    ]
  }

  assert {
    condition     = rhcs_identity_provider.htpasswd_identity_provider[0].cluster == "fake-cluster-123"
    error_message = "Expected cluster id on htpasswd identity provider."
  }

  assert {
    condition     = length(rhcs_identity_provider.htpasswd_identity_provider[0].htpasswd.users) == 1
    error_message = "Expected one htpasswd user in planned resource."
  }
}

# terraform-redhat/rhcs 1.7.13 marks the identity provider `ca` attributes
# sensitive. The matching module inputs are sensitive too, and the value still
# reaches the resource. issensitive() reports the sensitivity directly, so
# removing `sensitive = true` from openid_idp_ca fails this run.
run "openid_idp_ca_is_sensitive_and_propagates" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id               = "fake-cluster-123"
    name                     = "test-openid-ca"
    idp_type                 = "openid"
    openid_idp_client_id     = "fake-openid-client"
    openid_idp_client_secret = "fake-openid-secret"
    openid_idp_issuer        = "https://issuer.example.com"
    openid_idp_claims_email  = ["email"]
    openid_idp_ca            = "-----BEGIN CERTIFICATE-----\nfake\n-----END CERTIFICATE-----\n"
  }

  assert {
    condition     = issensitive(var.openid_idp_ca)
    error_message = "openid_idp_ca must be a sensitive variable."
  }

  assert {
    condition     = nonsensitive(var.openid_idp_ca) == "-----BEGIN CERTIFICATE-----\nfake\n-----END CERTIFICATE-----\n"
    error_message = "Expected openid_idp_ca to carry the configured value."
  }

  assert {
    condition     = nonsensitive(rhcs_identity_provider.openid_identity_provider[0].openid.ca) == "-----BEGIN CERTIFICATE-----\nfake\n-----END CERTIFICATE-----\n"
    error_message = "Expected openid_idp_ca to reach the openid.ca attribute as a sensitive value."
  }
}

# github_idp_ca, gitlab_idp_ca and ldap_idp_ca carry the same sensitivity.
run "ldap_idp_ca_is_sensitive_and_propagates" {
  command = plan

  providers = {
    rhcs = rhcs.default
  }

  variables {
    cluster_id   = "fake-cluster-123"
    name         = "test-ldap-ca"
    idp_type     = "ldap"
    ldap_idp_url = "ldaps://ldap.example.com/ou=users,dc=example,dc=com?uid"
    ldap_idp_ca  = "-----BEGIN CERTIFICATE-----\nfake\n-----END CERTIFICATE-----\n"
  }

  assert {
    condition     = issensitive(var.ldap_idp_ca)
    error_message = "ldap_idp_ca must be a sensitive variable."
  }

  assert {
    condition     = nonsensitive(rhcs_identity_provider.ldap_identity_provider[0].ldap.ca) == "-----BEGIN CERTIFICATE-----\nfake\n-----END CERTIFICATE-----\n"
    error_message = "Expected ldap_idp_ca to reach the ldap.ca attribute as a sensitive value."
  }
}

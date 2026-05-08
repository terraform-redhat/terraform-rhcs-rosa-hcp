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

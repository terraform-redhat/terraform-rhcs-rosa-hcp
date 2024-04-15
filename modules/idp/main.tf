resource "rhcs_identity_provider" "github_identity_provider" {
  count = lower(var.idp_type) == "github" ? 1 : 0

  cluster        = var.cluster_id
  name           = var.name
  mapping_method = var.mapping_method
  github = {
    client_id     = var.github_idp_client_id
    client_secret = var.github_idp_client_secret
    ca            = var.github_idp_ca
    hostname      = var.github_idp_hostname
    organizations = var.github_idp_organizations
    teams         = var.github_idp_teams
  }

  lifecycle {
    precondition {
      condition     = (lower(var.idp_type) == "github" && var.github_idp_client_id == null) == false
      error_message = "\"github_idp_client_id\" mustn't be empty when creating Github Identity Provider."
    }
    precondition {
      condition     = (lower(var.idp_type) == "github" && var.github_idp_client_secret == null) == false
      error_message = "\"github_idp_client_secret\" mustn't be empty when creating Github Identity Provider."
    }
  }
}

resource "rhcs_identity_provider" "gitlab_identity_provider" {
  count = lower(var.idp_type) == "gitlab" ? 1 : 0

  cluster        = var.cluster_id
  name           = var.name
  mapping_method = var.mapping_method
  gitlab = {
    client_id     = var.gitlab_idp_client_id
    client_secret = var.gitlab_idp_client_secret
    url           = var.gitlab_idp_url
    ca            = var.gitlab_idp_ca
  }

  lifecycle {
    precondition {
      condition     = (lower(var.idp_type) == "gitlab" && var.gitlab_idp_client_id == null) == false
      error_message = "\"gitlab_idp_client_id\" mustn't be empty when creating Gitlab Identity Provider."
    }
    precondition {
      condition     = (lower(var.idp_type) == "gitlab" && var.gitlab_idp_client_secret == null) == false
      error_message = "\"gitlab_idp_client_secret\" mustn't be empty when creating Gitlab Identity Provider."
    }
    precondition {
      condition     = (lower(var.idp_type) == "gitlab" && var.gitlab_idp_url == null) == false
      error_message = "\"gitlab_idp_url\" mustn't be empty when creating Gitlab Identity Provider."
    }
  }
}

resource "rhcs_identity_provider" "google_identity_provider" {
  count = lower(var.idp_type) == "google" ? 1 : 0

  cluster        = var.cluster_id
  name           = var.name
  mapping_method = var.mapping_method
  google = {
    client_id     = var.google_idp_client_id
    client_secret = var.google_idp_client_secret
    hosted_domain = var.google_idp_hosted_domain
  }

  lifecycle {
    precondition {
      condition     = (lower(var.idp_type) == "google" && var.google_idp_client_id == null) == false
      error_message = "\"google_idp_client_id\" mustn't be empty when creating Google Identity Provider."
    }
    precondition {
      condition     = (lower(var.idp_type) == "google" && var.google_idp_client_secret == null) == false
      error_message = "\"google_idp_client_secret\" mustn't be empty when creating Google Identity Provider."
    }
  }
}

resource "rhcs_identity_provider" "htpasswd_identity_provider" {
  count = lower(var.idp_type) == "htpasswd" ? 1 : 0

  cluster        = var.cluster_id
  name           = var.name
  mapping_method = var.mapping_method
  htpasswd = {
    users = var.htpasswd_idp_users
  }

  lifecycle {
    precondition {
      condition     = (lower(var.idp_type) == "htpasswd" && var.htpasswd_idp_users == null) == false
      error_message = "\"htpasswd_idp_users\" mustn't be empty when creating Htpasswd Identity Provider."
    }
  }
}

resource "rhcs_identity_provider" "ldap_identity_provider" {
  count = lower(var.idp_type) == "ldap" ? 1 : 0

  cluster        = var.cluster_id
  name           = var.name
  mapping_method = var.mapping_method
  ldap = {
    bind_dn       = var.ldap_idp_bind_dn
    bind_password = var.ldap_idp_bind_password
    ca            = var.ldap_idp_ca
    insecure      = var.ldap_idp_insecure
    url           = var.ldap_idp_url
    attributes = {
      email              = var.ldap_idp_emails
      id                 = var.ldap_idp_ids
      name               = var.ldap_idp_names
      preferred_username = var.ldap_idp_preferred_usernames
    }
  }

  lifecycle {
    precondition {
      condition     = (lower(var.idp_type) == "ldap" && var.ldap_idp_url == null) == false
      error_message = "\"ldap_idp_url\" mustn't be empty when creating LDAP Identity Provider."
    }
  }
}

resource "rhcs_identity_provider" "openid_identity_provider" {
  count = lower(var.idp_type) == "openid" ? 1 : 0

  cluster        = var.cluster_id
  name           = var.name
  mapping_method = var.mapping_method
  openid = {
    ca = var.openid_idp_ca
    claims = {
      email              = var.openid_idp_claims_email
      groups             = var.openid_idp_claims_groups
      name               = var.openid_idp_claims_name
      preferred_username = var.openid_idp_claims_preferred_username
    }
    client_id                  = var.openid_idp_client_id
    client_secret              = var.openid_idp_client_secret
    extra_scopes               = var.openid_idp_extra_scopes
    extra_authorize_parameters = var.openid_idp_extra_authorize_parameters
    issuer                     = var.openid_idp_issuer
  }

  lifecycle {
    precondition {
      condition     = (lower(var.idp_type) == "openid" && var.openid_idp_client_id == null) == false
      error_message = "\"openid_idp_client_id\" mustn't be empty when creating OpenID Identity Provider."
    }
    precondition {
      condition     = (lower(var.idp_type) == "openid" && var.openid_idp_client_secret == null) == false
      error_message = "\"openid_idp_client_secret\" mustn't be empty when creating OpenID Identity Provider."
    }
  }
}

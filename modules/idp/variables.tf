variable "cluster_id" {
  description = "Identifier of the cluster."
  type        = string
}

variable "name" {
  description = "Name of the identity provider."
  type        = string
}

variable "idp_type" {
  type        = string
  description = ""
  validation {
    condition     = contains(["github", "gitlab", "google", "htpasswd", "ldap", "openid"], lower(var.idp_type))
    error_message = " idp_type must be one of the following: [\"github\", \"gitlab\", \"google\", \"htpasswd\", \"ldap\", \"openid\"]"
  }
}

variable "mapping_method" {
  type        = string
  default     = null
  description = "Specifies how new identities are mapped to users when they log in. Options are add, claim, generate and lookup. (default is claim)"
}

#########################
# Github IDP
#########################

variable "github_idp_client_id" {
  type        = string
  default     = null
  description = "Client secret issued by Github (required). Valid only to Github Identity Provider (idp_type=github)"
}

variable "github_idp_client_secret" {
  type        = string
  default     = null
  description = "Client secret issued by Github (required). Valid only to Github Identity Provider (idp_type=github)"
}

variable "github_idp_ca" {
  type        = string
  default     = null
  description = "Path to PEM-encoded certificate file to use when making requests to the server (optional). Valid only to Github Identity Provider (idp_type=github)"
}

variable "github_idp_hostname" {
  type        = string
  default     = null
  description = "Optional domain to use with a hosted instance of GitHub Enterprise (optional). Valid only to Github Identity Provider (idp_type=github)"
}

variable "github_idp_organizations" {
  type        = list(string)
  default     = null
  description = "Only users that are members of at least one of the listed organizations will be allowed to log in (optional). Valid only to Github Identity Provider (idp_type=github)"
}

variable "github_idp_teams" {
  type        = list(string)
  default     = null
  description = "Only users that are members of at least one of the listed teams will be allowed to log in. The format is `<org>`/`<team>` (optional). Valid only to Github Identity Provider (idp_type=github)"
}

#########################
# Gitlab IDP
#########################

variable "gitlab_idp_client_id" {
  type        = string
  default     = null
  description = "Client identifier of a registered Gitlab OAuth application (required). Valid only to Gitlab Identity Provider (idp_type=gitlab)"
}

variable "gitlab_idp_client_secret" {
  type        = string
  default     = null
  description = "Client secret issued by Gitlab (required). Valid only to Gitlab Identity Provider (idp_type=gitlab)"
}

variable "gitlab_idp_url" {
  type        = string
  default     = null
  description = "URL of the Gitlab instance (required). Valid only to Gitlab Identity Provider (idp_type=gitlab)"
}

variable "gitlab_idp_ca" {
  type        = string
  default     = null
  description = "Trusted certificate authority bundle (optional). Valid only to Gitlab Identity Provider (idp_type=gitlab)"
}

#########################
# Google IDP
#########################

variable "google_idp_client_id" {
  type        = string
  default     = null
  description = "Client identifier of a registered Google OAuth application (required). Valid only to Google Identity Provider (idp_type=google)"
}

variable "google_idp_client_secret" {
  type        = string
  default     = null
  description = "Client secret issued by Google (required). Valid only to Google Identity Provider (idp_type=google)"
}

variable "google_idp_hosted_domain" {
  type        = string
  default     = null
  description = "Restrict users to a Google Apps domain (optional). Valid only to Google Identity Provider (idp_type=google)"
}

#########################
# Htpasswd IDP
#########################

variable "htpasswd_idp_users" {
  type = list(object({
    username = string
    password = string
  }))
  default     = null
  description = "A list of htpasswd user credentials (required). Valid only to Htpasswd Identity Provider (idp_type=htpasswd)"
}

#########################
# LDAP IDP
#########################

variable "ldap_idp_bind_dn" {
  type        = string
  default     = null
  description = "DN to bind with during the search phase (optional). Valid only to Ldap Identity Provider (idp_type=ldap)"
}

variable "ldap_idp_bind_password" {
  type        = string
  default     = null
  description = "Password to bind with during the search phase (optional). Valid only to Ldap Identity Provider (idp_type=ldap)"
}

variable "ldap_idp_ca" {
  type        = string
  default     = null
  description = "Trusted certificate authority bundle (optional). Valid only to Ldap Identity Provider (idp_type=ldap)"
}

variable "ldap_idp_insecure" {
  type        = bool
  default     = null
  description = "Do not make TLS connections to the server (optional). Valid only to Ldap Identity Provider (idp_type=ldap)"
}

variable "ldap_idp_url" {
  type        = string
  default     = null
  description = "An RFC 2255 URL which specifies the LDAP search parameters to use (required). Valid only to Ldap Identity Provider (idp_type=ldap)"
}

variable "ldap_idp_emails" {
  type        = list(string)
  default     = null
  description = "The list of attributes whose values should be used as the email address (optional). Valid only to Ldap Identity Provider (idp_type=ldap)"
}

variable "ldap_idp_ids" {
  type        = list(string)
  default     = null
  description = "The list of attributes whose values should be used as the user ID. Default ['dn'] (optional). Valid only to Ldap Identity Provider (idp_type=ldap)"
}

variable "ldap_idp_names" {
  type        = list(string)
  default     = null
  description = "The list of attributes whose values should be used as the display name. Default ['cn'] (optional). Valid only to Ldap Identity Provider (idp_type=ldap)"
}

variable "ldap_idp_preferred_usernames" {
  type        = list(string)
  default     = null
  description = "The list of attributes whose values should be used as the preferred username. Default ['uid'] (optional). Valid only to Ldap Identity Provider (idp_type=ldap)"
}

#########################
# OpenID IDP
#########################

variable "openid_idp_ca" {
  type        = string
  default     = null
  description = "Trusted certificate authority bundle (optional). Valid only to OpenID Identity Provider (idp_type=openid)"
}

variable "openid_idp_claims_email" {
  type        = list(string)
  default     = null
  description = "List of claims to use as the email address (optional). Valid only to OpenID Identity Provider (idp_type=openid)"
}

variable "openid_idp_claims_groups" {
  type        = list(string)
  default     = null
  description = "List of claims to use as the groups names (optional). Valid only to OpenID Identity Provider (idp_type=openid)"
}

variable "openid_idp_claims_name" {
  type        = list(string)
  default     = null
  description = "List of claims to use as the display name (optional). Valid only to OpenID Identity Provider (idp_type=openid)"
}

variable "openid_idp_claims_preferred_username" {
  type        = list(string)
  default     = null
  description = "List of claims to use as the preferred username when provisioning a user (optional). Valid only to OpenID Identity Provider (idp_type=openid)"
}

variable "openid_idp_client_id" {
  type        = string
  default     = null
  description = "Client ID from the registered application (required). Valid only to OpenID Identity Provider (idp_type=openid)"
}

variable "openid_idp_client_secret" {
  type        = string
  default     = null
  description = "Client Secret from the registered application (required). Valid only to OpenID Identity Provider (idp_type=openid)"
}

variable "openid_idp_extra_scopes" {
  type        = list(string)
  default     = null
  description = "List of scopes to request, in addition to the 'openid' scope, during the authorization token request (optional). Valid only to OpenID Identity Provider (idp_type=openid)"
}

variable "openid_idp_extra_authorize_parameters" {
  type        = map(string)
  default     = null
  description = "Extra authorization parameters for the OpenID Identity Provider (optional). Valid only to OpenID Identity Provider (idp_type=openid)"
}

variable "openid_idp_issuer" {
  type        = string
  default     = null
  description = "The URL that the OpenID Provider asserts as the Issuer Identifier. It must use the https scheme with no URL query parameters or fragment (required). Valid only to OpenID Identity Provider (idp_type=openid)"
}

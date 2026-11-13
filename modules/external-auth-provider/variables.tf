# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

// Required
variable "cluster_id" {
  description = "Identifier of the ROSA HCP cluster. The cluster must be in a ready state and must have been created with external authentication enabled."
  type        = string

  validation {
    condition     = var.cluster_id == null ? false : trimspace(var.cluster_id) != ""
    error_message = "cluster_id must be a non-empty string (not blank or whitespace)."
  }
}

// Required
variable "name" {
  description = "Name of the external authentication provider. OCM uses this name as the identifier of the provider. Changing this value replaces the provider."
  type        = string

  validation {
    condition     = var.name == null ? false : trimspace(var.name) != ""
    error_message = "name must be a non-empty string (not blank or whitespace)."
  }
}

// Required
variable "issuer_url" {
  description = "HTTPS URL of the OIDC token issuer. Must be an absolute HTTPS URL with a host and without user information."
  type        = string

  validation {
    condition     = var.issuer_url == null ? false : can(regex("^(?i:https)://[^/?#@]+([/?#].*)?$", var.issuer_url))
    error_message = "issuer_url must be an absolute HTTPS URL with a host and no user information, for example https://issuer.example.com."
  }
}

// Required
variable "issuer_audiences" {
  description = "Audiences for which tokens from the issuer are valid. Supply between one and ten values. When console_client_id is set, it must also appear in this set."
  type        = set(string)

  validation {
    condition     = var.issuer_audiences == null ? false : (length(var.issuer_audiences) >= 1 && length(var.issuer_audiences) <= 10)
    error_message = "issuer_audiences must contain between one and ten values."
  }

  validation {
    condition = var.issuer_audiences == null ? false : alltrue([
      for audience in var.issuer_audiences : try(trimspace(audience), "") != ""
    ])
    error_message = "Each issuer_audiences value must be a non-null, non-empty string (not blank or whitespace)."
  }
}

// Optional
variable "issuer_ca" {
  description = "PEM-encoded CA certificate bundle content for the issuer, for example file(\"ca.pem\"). This is certificate content, not a file path. Set an empty string to clear the value. When null (default), the current API value is recorded in state."
  type        = string
  default     = null

  validation {
    condition     = var.issuer_ca == null ? true : (var.issuer_ca == "" || can(regex("-----BEGIN CERTIFICATE-----", var.issuer_ca)))
    error_message = "issuer_ca must be empty or contain PEM certificate content, for example file(\"ca.pem\"). A file path is not accepted."
  }
}

// Optional
variable "claim_mapping_groups_claim" {
  description = "ID token claim used to map groups. Set an empty string to clear the value. When null (default), the current API value is recorded in state."
  type        = string
  default     = null

  validation {
    condition     = var.claim_mapping_groups_claim == null ? true : (var.claim_mapping_groups_claim == "" || trimspace(var.claim_mapping_groups_claim) != "")
    error_message = "claim_mapping_groups_claim must not be blank. Use an empty string to clear it."
  }
}

// Optional
variable "claim_mapping_username_claim" {
  description = "ID token claim used to construct usernames. Set an empty string to clear the value. When null (default), the current API value is recorded in state."
  type        = string
  default     = null

  validation {
    condition     = var.claim_mapping_username_claim == null ? true : (var.claim_mapping_username_claim == "" || trimspace(var.claim_mapping_username_claim) != "")
    error_message = "claim_mapping_username_claim must not be blank. Use an empty string to clear it."
  }
}

// Optional
variable "claim_validation_rule" {
  description = "Rules for token claims in claim:required_value format. The first colon separates the claim from the required value; later colons belong to the required value. Set an empty list to clear the rules. When null (default), the current API value is recorded in state."
  type        = list(string)
  default     = null

  # (?s) lets the required value span newlines, matching the provider's
  # strings.SplitN(rule, ":", 2) + TrimSpace check rather than tightening it.
  validation {
    condition = var.claim_validation_rule == null ? true : alltrue([
      for rule in var.claim_validation_rule : can(regex("^(?s:[^:]*[^:\\s][^:]*:.*\\S.*)$", rule))
    ])
    error_message = "Each claim_validation_rule value must follow claim:required_value with both parts non-empty."
  }
}

// Optional
variable "console_client_id" {
  description = "OIDC client ID used by the OpenShift console. Must be set together with console_client_secret and must appear in issuer_audiences. Set both console client fields to empty strings to remove the console client. When null (default), the current API value is recorded in state."
  type        = string
  default     = null

  validation {
    condition     = var.console_client_id == null ? true : (var.console_client_id == "" || trimspace(var.console_client_id) != "")
    error_message = "console_client_id must not be blank. Use empty strings on both console client fields to remove the console client."
  }
}

// Optional
variable "console_client_secret" {
  description = "OIDC client secret for the OpenShift console. Must be set together with console_client_id. The API never returns this value, so an import leaves it null in state and it must be present in the configuration before updating a confidential console client. Set both console client fields to empty strings to remove the console client."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.console_client_secret == null ? true : (var.console_client_secret == "" || trimspace(var.console_client_secret) != "")
    error_message = "console_client_secret must not be blank. Use empty strings on both console client fields to remove the console client."
  }
}

// Optional
variable "console_extra_scopes" {
  description = "Additional scopes requested by the OpenShift console client. Requires console_client_id and console_client_secret. Set an empty set to clear the scopes. When null (default), the current API value is recorded in state."
  type        = set(string)
  default     = null

  validation {
    condition = var.console_extra_scopes == null ? true : alltrue([
      for scope in var.console_extra_scopes : try(scope != "" && !can(regex("\\s", scope)), false)
    ])
    error_message = "Each console_extra_scopes value must be a single, non-empty scope without whitespace."
  }
}

// Optional
variable "create_external_auth_provider" {
  description = "Create the external authentication provider. Creating a provider that already exists fails, because the API returns a conflict. To let Terraform adopt an existing provider, keep this true and run terraform import '<module address>.rhcs_external_auth_provider.this[0]' <cluster_id>,<name> (quote the address: [0] is a shell glob). To leave an existing provider unmanaged, set this to false; Terraform then creates nothing. Setting this to false for a provider that is already in state destroys that provider. (default: true)"
  type        = bool
  default     = true
}

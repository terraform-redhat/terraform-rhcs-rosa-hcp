// Required
variable "cluster_id" {
  description = "Identifier of the cluster."
  type        = string
}

// Required
variable "name" {
  description = "Name of the identity provider."
  type        = string
}

variable "github" {
  description = "Details of the Github identity provider."
  type        = map(any)
  default     = {}
}

variable "gitlab" {
  description = "Details of the Gitlab identity provider. "
  type        = map(any)
  default     = {}
}

variable "google" {
  description = "Details of the Google identity provider."
  type        = map(any)
  default     = {}
}

variable "htpasswd" {
  description = "Details of the 'htpasswd' identity provider. "
  type        = map(any)
  default     = {}
}

variable "ldap" {
  description = "Details of the LDAP identity provider"
  type        = map(any)
  default     = {}
}

variable "openid" {
  description = "Details of the OpenID identity provider."
  type        = map(any)
  default     = {}
}

variable "mapping_method" {
  description = "Specifies how new identities are mapped to users when they log in. Options are add, claim, generate and lookup. (default is claim)"
  type        = string
}
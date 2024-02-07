variable "managed" {
  type        = bool
  description = "Indicates whether it is a Red Hat managed or unmanaged (Customer hosted) OIDC Configuration"
  default     = true
}

variable "secret_arn" {
  type        = string
  description = "Indicates for unmanaged OIDC config, the secret ARN"
  default     = null
}

variable "issuer_url" {
  type        = string
  description = "Indicates for unmanaged OIDC config, the bucket URL"
  default     = null
}

variable "installer_role_arn" {
  type        = string
  description = "STS Role ARN with get secrets permission"
  default     = null
}

variable "cluster_id" {
  type        = string
  description = "The cluster ID"
  default     = ""
}

variable "tags" {
  description = "List of AWS resource tags to apply."
  type        = map(string)
  default     = null
}

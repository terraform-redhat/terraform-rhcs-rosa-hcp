variable "managed" {
  type        = bool
  default     = true
  description = "Indicates whether it is a Red Hat managed or unmanaged (Customer hosted) OIDC Configuration. This value should not be updated, please create a new resource instead."
}

variable "installer_role_arn" {
  type        = string
  default     = null
  description = "The Amazon Resource Name (ARN) associated with the AWS IAM role used by the ROSA installer. Applicable exclusively to unmanaged OIDC; otherwise, leave empty."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "List of AWS resource tags to apply."
}

variable "oidc_prefix" {
  type        = string
  description = "Optional prefix for the OIDC resources (if you're using managed policies). Maximum 16 characters, must match pattern: ^[a-z][a-z0-9\\-]+[a-z0-9]$"
  default     = null

  validation {
    condition     = var.oidc_prefix == null || length(var.oidc_prefix) <= 16
    error_message = "The oidc_prefix must be maximum 16 characters"
  }

  validation {
    condition     = var.oidc_prefix == null || can(regex("^[a-z][a-z0-9\\-]+[a-z0-9]$", var.oidc_prefix))
    error_message = "The oidc_prefix must start with a lowercase letter, contain only lowercase letters/numbers/hyphens, and end with a lowercase letter or number. Pattern: ^[a-z][a-z0-9\\-]+[a-z0-9]$"
  }
}

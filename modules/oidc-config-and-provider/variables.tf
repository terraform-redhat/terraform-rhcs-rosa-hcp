variable "managed" {
  type        = bool
  default     = true
  description = "Indicates whether it is a Red Hat managed or unmanaged (Customer hosted) OIDC Configuration"
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

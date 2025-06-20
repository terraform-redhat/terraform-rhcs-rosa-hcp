variable "account_role_prefix" {
  type        = string
  description = "Prefix to be used when creating the account roles"
  default     = "tf-acc"
}

variable "path" {
  description = "(Optional) The arn path for the account/operator roles as well as their policies. Must begin and end with '/'."
  type        = string
  default     = "/"
}

variable "permissions_boundary" {
  description = "The ARN of the policy that is used to set the permissions boundary for the IAM roles in STS clusters."
  type        = string
  default     = ""
}

variable "permissions_boundary_overrides" {
  description = "Map of AWS role names to custom permission boundary ARNs. If not set for a role, uses the default permissions_boundary"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "List of AWS resource tags to apply."
  type        = map(string)
  default     = null
}

variable "account_role_prefix" {
  type    = string
  description = "Prefix to be used when creating the account roles"
  default = "tf-acc"
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

variable "tags" {
  description = "Mapping of AWS resource tags to apply."
  type        = map(string)
  default     = null
}

variable "attach_worker_role_zero_egress_policy" {
  description = "Signals to attach zero egress policy to worker role"
  type        = bool
  default     = false
}

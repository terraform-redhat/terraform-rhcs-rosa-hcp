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

variable "shared_vpc_roles" {
  description = "Mapping of shared vpc roles, available keys are [route53, vpce]"
  type        = map(string)
  default = {
    "route53" : "",
    "vpce" : ""
  }
}

variable "create_shared_vpc_policies" {
  description = "Signals to create the shared vpc policies, it might not be needed if created through another step"
  type        = bool
  default     = false
}

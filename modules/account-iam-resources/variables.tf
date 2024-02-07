variable "account_role_prefix" {
  type    = string
  default = null
}

variable "openshift_version" {
  description = "The Openshift cluster version of the cluster those account roles are used for. Only major and minor parts (for example 4.1)"
  type        = string
  default     = "4.13"
}

variable "path" {
  description = "(Optional) The arn path for the account/operator roles as well as their policies."
  type        = string
  default     = "/"
}

variable "permissions_boundary" {
  description = "The ARN of the policy that is used to set the permissions boundary for the IAM roles in STS clusters."
  type        = string
  default     = ""
}

variable "tags" {
  description = "List of AWS resource tags to apply."
  type        = map(string)
  default     = null
}

variable "operator_role_prefix" {
  type = string
}

variable "account_role_prefix" {
  type = string
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

variable "cluster_id" {
  description = "cluster ID"
  type        = string
  default     = ""
}

variable "tags" {
  description = "List of AWS resource tags to apply."
  type        = map(string)
  default     = null
}

variable "oidc_endpoint_url" {
  description = "oidc provider url"
  type        = string
}

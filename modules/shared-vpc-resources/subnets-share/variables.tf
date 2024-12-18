variable "name_prefix" {
  type        = string
  description = "The prefix applied to all AWS creations."
}

variable "target_aws_account" {
  type        = string
  description = "The AWS account number where the cluster is created."
}

variable "subnets" {
  type        = list(string)
  description = "The list of the subnets that must be shared between the accounts."
}
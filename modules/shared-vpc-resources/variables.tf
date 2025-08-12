variable "cluster_name" {
  type        = string
  description = "The cluster's name for which shared resources are created. It is used for the hosted zone domain."
}

variable "name_prefix" {
  type        = string
  description = "The prefix applied to all AWS creations."
}

variable "target_aws_account" {
  type        = string
  description = "The AWS account number where the cluster is created."
}

variable "operator_roles_prefix" {
  type        = string
  description = "Prefix used to compute ingress and control plane operator roles"
}

variable "account_roles_prefix" {
  type        = string
  description = "Prefix used to compute installer account role"
}

variable "subnets" {
  type        = list(string)
  description = "The list of the subnets that must be shared between the accounts."
}

variable "ingress_private_hosted_zone_base_domain" {
  type        = string
  description = "The base domain that must be used for hosted zone creation."
}

variable "vpc_id" {
  type        = string
  description = "The Shared VPC ID."
}

variable "route53_permission_boundary" {
  type        = string
  default     = null
  description = "Route53 role permission boundary arn"
}

variable "vpce_permission_boundary" {
  type        = string
  default     = null
  description = "VPCE role permission boundary arn"
}

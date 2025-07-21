variable "cluster_name" {
  type        = string
  description = "The cluster's name for which shared resources are created. It is used for the hosted zone domain."
}

variable "ingress_private_hosted_zone_base_domain" {
  type        = string
  description = "The base domain that must be used for hosted zone creation."
}

variable "vpc_id" {
  type        = string
  description = "The main VPC ID."
}

variable "secondary_vpc_id" {
  type        = string
  default     = null
  description = "The secondary VPC ID. To be used when association authorization is required"
}

variable "create_association_authorization" {
  type        = bool
  default     = false
  description = "Indicates need to create association authorization"
}

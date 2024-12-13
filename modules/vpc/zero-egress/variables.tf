variable "cidr_blocks" {
  type        = list(string)
  default     = null
  description = "CIDR ranges to include as ingress allowed ranges"
}

variable "vpc_id" {
  type        = string
  description = "ID of the AWS VPC resource"
}

variable "subnet_ids" {
  type        = list(string)
  description = "ID of the subnets resource"
}
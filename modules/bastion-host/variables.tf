variable "prefix" {
  type        = string
  description = "Prefix for the name of each AWS resource"
}

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
  description = "Set of subnet IDs to instantiate a bastion host against"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Instance type of the bastion hosts"
}

variable "ami_id" {
  type        = string
  default     = null
  description = "Amazon Machine Image to run the bastion host with"
}

variable "user_data_file" {
  type        = string
  default     = null
  description = "User data for proxy configuration"
}

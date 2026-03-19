variable "aws_subnet_id" {
  type        = string
  description = "ROSA cluster subnet ID. Used to retrieve VPC ID the subnet belongs to."
}

variable "cluster_id" {
  type        = string
  description = "Identifier of the cluster."
}

variable "aws_additional_control_plane_security_group_ids" {
  type        = list(string)
  default     = []
  description = "The additional security group IDs to be added to the control plane VPC endpoint."
}

variable "aws_subnet_ids" {
  type        = string
  description = "ROSA cluster subnet ID. Used to retrieve VPC ID the subnet belongs to."
}

variable "cluster_id" {
  type        = string
  description = "ROSA cluster ID"
}

variable "aws_additional_control_plane_security_group_ids" {
  type        = list(string)
  default     = null
  description = "The additional security group IDs to be added to the control plane VPC endpoint."
  validation {
    condition     = var.aws_additional_control_plane_security_group_ids == null || length(var.aws_additional_control_plane_security_group_ids) > 0
    error_message = "Security group list cannot be empty."
  }
}

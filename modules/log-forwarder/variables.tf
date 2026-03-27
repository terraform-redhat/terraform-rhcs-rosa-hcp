variable "cluster_id" {
  description = "Identifier of the cluster."
  type        = string
}

variable "s3" {
  description = "S3 destination for log forwarding. Mutually exclusive with cloudwatch. See rhcs_log_forwarder resource documentation."
  type = object({
    bucket_name   = string
    bucket_prefix = optional(string)
  })
  default = null
}

variable "cloudwatch" {
  description = "CloudWatch destination for log forwarding. Mutually exclusive with s3. See rhcs_log_forwarder resource documentation."
  type = object({
    log_group_name            = string
    log_distribution_role_arn = string
  })
  default = null
}

variable "applications" {
  description = "List of additional applications to forward logs for. At least one of applications or groups must be non-empty (provider requirement)."
  type        = list(string)
  default     = null
}

variable "groups" {
  description = "List of log forwarder groups. At least one of applications or groups must be non-empty (provider requirement)."
  type = list(object({
    id      = string
    version = optional(string)
  }))
  default = null
}

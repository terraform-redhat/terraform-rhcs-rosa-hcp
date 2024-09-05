// Required
variable "cluster_id" {
  description = "Identifier of the cluster."
  type        = string
}

// Required
variable "name" {
  description = "Name of the KubeletConfig."
  type        = string
}

// Required
variable "pod_pids_limit" {
  description = "Sets the requested podPidsLimit to be applied as part of the custom KubeletConfig."
  type        = number
  default     = null
}



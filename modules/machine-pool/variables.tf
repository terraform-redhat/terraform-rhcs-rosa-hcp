// Required
variable "cluster_id" {
  description = "Identifier of the cluster."
  type        = string
}

// Required
variable "name" {
  description = "Name of the machine pool. Must consist of lower-case alphanumeric characters or '-', start and end with an alphanumeric character."
  type        = string
}

variable "replicas" {
  description = "The amount of the machine created in this machine pool."
  type        = number
  default     = null
}

variable "taints" {
  description = "Taints for a machine pool. This list will overwrite any modifications made to node taints on an ongoing basis."
  type = list(object({
    key           = string
    value         = string
    schedule_type = string
  }))
  default = null
}

variable "labels" {
  description = "Labels for the machine pool. Format should be a comma-separated list of 'key = value'. This list will overwrite any modifications made to node labels on an ongoing basis."
  type        = map(string)
  default     = null
}

variable "subnet_id" {
  description = "Select the subnet in which to create a single AZ machine pool for BYO-VPC cluster"
  type        = string
  nullable    = false
}

variable "autoscaling" {
  type = object({
    enabled      = bool
    min_replicas = number
    max_replicas = number
  })
  default = {
    enabled      = false
    min_replicas = null
    max_replicas = null
  }
  nullable    = false
  description = "Configures autoscaling for the pool."
}

variable "aws_node_pool" {
  type = object({
    instance_type = string
    tags          = map(string)
  })
  nullable    = false
  description = "Configures aws settings for the pool."
}

variable "auto_repair" {
  type        = bool
  default     = true
  description = "Configures auto repair option for the pool."
}

variable "openshift_version" {
  type        = string
  description = "Desired version of OpenShift for the cluster, for example '4.1.0'. If version is greater than the currently running version, an upgrade will be scheduled."
  nullable    = false
}

variable "upgrade_acknowledgements_for" {
  type        = string
  default     = null
  description = "Indicates acknowledgement of agreements required to upgrade the cluster version between minor versions (e.g. a value of \"4.12\" indicates acknowledgement of any agreements required to upgrade to OpenShift 4.12.z from 4.11 or before)."
}

variable "tuning_configs" {
  type        = list(string)
  default     = null
  description = "A list of tuning config names to attach to this machine pool. The tuning configs must already exist"
}

variable "kubelet_configs" {
  type        = string
  default     = null
  description = "Name of the kubelet configs to attach to this machine pool. The kubelet configs must already exist"
}

variable "ignore_deletion_error" {
  type        = bool
  default     = false
  description = "Ignore machine pool deletion error. Assists when cluster resource is managed within the same file for the destroy use case"
}

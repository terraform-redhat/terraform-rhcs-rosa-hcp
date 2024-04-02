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
  type        = list(object({
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
  default     = null
}

variable "autoscaling" {
  type = object({
    enabled = bool
    min_replicas = number
    max_replicas = number
  })
  default = {
    enabled = false
    min_replicas = null
    max_replicas = null
  }
  description = "Configures autoscaling for the pool."
}

variable "aws_node_pool" {
  type = object({
    instance_type = string
    tags = map(string)
  })
  default = null
  description = "Configures aws settings for the pool."
}

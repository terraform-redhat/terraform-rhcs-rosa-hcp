// Required
variable "cluster_id" {
  description = "Identifier of the cluster."
  type        = string
}

// Required
variable "type" {
  description = "The type of the image digest mirror set."
  type        = string
}

// Required
variable "source_registry" {
  description = "The source registry hostname."
  type        = string
}

// Required
variable "mirrors" {
  description = "List of mirror registry hostnames."
  type        = list(string)
}
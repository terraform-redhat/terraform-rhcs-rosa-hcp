variable "openshift_version" {
  type    = string
  default = "4.14.9"
  validation {
    condition     = can(regex("^[0-9]*[0-9]+.[0-9]*[0-9]+.[0-9]*[0-9]+$", var.openshift_version))
    error_message = "openshift_version must be with structure <major>.<minor>.<patch> (for example 4.13.6)."
  }
}

variable "cluster_name" {
  type = string
}

variable "multi_az" {
  description = "Create the vpc subnets in only one AZ"
  type        = bool
  default     = true
}

variable "machine_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

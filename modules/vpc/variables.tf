variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "Cidr block of the desired VPC. This value should not be updated, please create a new resource instead"
}

variable "name_prefix" {
  type        = string
  description = "User-defined prefix for all generated AWS resources of this VPC. This value should not be updated, please create a new resource instead"
}

variable "availability_zones" {
  type        = list(string)
  default     = null
  description = "A list of availability zones names in the region.  This value should not be updated, please create a new resource instead"
}

variable "availability_zones_count" {
  type        = number
  default     = null
  description = "The count of availability zones to utilize within the specified AWS Region, where pairs of public and private subnets will be generated. Valid only when availability_zones variable is not provided. This value should not be updated, please create a new resource instead"
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "AWS tags to be applied to generated AWS resources of this VPC."
}

variable "is_zero_egress" {
  type        = bool
  default     = false
  description = "Indicates intention for zero egress vpc."
}
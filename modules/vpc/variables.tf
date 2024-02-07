variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "name_prefix" {
  type = string
}

variable "subnet_count" {
  description = "The number of public/private subnet pairs to make."
  type        = number
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "AWS tags to be applied to created resources."
}

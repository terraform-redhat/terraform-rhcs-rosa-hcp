variable "name_prefix" {
  type        = string
  description = "The prefix applied to all AWS creations."
}

variable "installer_role_arn" {
  type        = string
  description = "The installer account role arn."
}

variable "control_plane_role_arn" {
  type        = string
  description = "The control plane role arn."
}

variable "permission_boundary" {
  type        = string
  default     = null
  description = "Permission boundary arn"
}

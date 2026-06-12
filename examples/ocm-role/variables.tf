# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

variable "ocm_role_prefix" {
  type        = string
  description = "User-defined prefix for the OCM IAM role name."
  default     = "ManagedOpenShift"
}

variable "profile" {
  type        = string
  description = "Profile of the OCM role to create. Allowed values are `standard`, `admin`, and `no-console`."
  default     = "standard"
}

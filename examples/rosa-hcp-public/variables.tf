# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

variable "openshift_version" {
  type        = string
  default     = "4.19.3"
  description = "The required version of Red Hat OpenShift for the cluster, for example '4.1.0'. If version is greater than the currently running version, an upgrade will be scheduled."
  validation {
    condition     = can(regex("^[0-9]*[0-9]+.[0-9]*[0-9]+.[0-9]*[0-9]+$", var.openshift_version))
    error_message = "openshift_version must be with structure <major>.<minor>.<patch> (for example 4.13.6)."
  }
}

variable "cluster_name" {
  type        = string
  description = "Name of the cluster. After the creation of the resource, it is not possible to update the attribute value."
}

variable "audit_log_arn" {
  type        = string
  default     = null
  description = "Optional ARN of an existing, user-created IAM role that forwards cluster audit logs to AWS CloudWatch. The role's trust policy must federate the cluster OIDC provider for the service account system:serviceaccount:openshift-config-managed:cloudwatch-audit-exporter. This example does not create the IAM role. Leave null to keep audit log forwarding disabled."
}

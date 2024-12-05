variable "cluster_name" {
  type        = string
  description = "Name of the cluster. After the creation of the resource, it is not possible to update the attribute value."
}

variable "openshift_version" {
  type        = string
  default     = "4.14.9"
  description = "The required version of Red Hat OpenShift for the cluster, for example '4.1.0'. If version is greater than the currently running version, an upgrade will be scheduled."
}

variable "version_channel_group" {
  type        = string
  default     = "stable"
  description = "Desired channel group of the version [stable, candidate, fast, nightly]."
}

variable "network_owner_aws_access_key_id" {
  type        = string
  default     = ""
  description = "The access key provides access to AWS services and is associated with the shared-vpc AWS account."
}

variable "network_owner_aws_secret_access_key" {
  type        = string
  default     = ""
  description = "The secret key paired with the access key. Together, they provide the necessary credentials for Terraform to authenticate with the shared-vpc AWS account and manage resources securely."
  sensitive   = true
}

variable "network_owner_aws_profile" {
  type        = string
  default     = ""
  description = "The name of the AWS profile configured in the AWS credentials file (typically located at ~/.aws/credentials). This profile contains the access key, secret key, and optional session token associated with the shared-vpc AWS account."
}

variable "network_owner_aws_shared_credentials_files" {
  type        = list(string)
  default     = null
  description = "List of files path to the AWS shared credentials file. This file typically contains AWS access keys and secret keys and is used when authenticating with AWS using profiles (default file located at ~/.aws/credentials)."
}

variable "cluster_owner_aws_access_key_id" {
  type        = string
  default     = ""
  description = "The access key provides access to AWS services and is associated with the shared-vpc AWS account."
}

variable "cluster_owner_aws_secret_access_key" {
  type        = string
  default     = ""
  description = "The secret key paired with the access key. Together, they provide the necessary credentials for Terraform to authenticate with the shared-vpc AWS account and manage resources securely."
  sensitive   = true
}

variable "cluster_owner_aws_profile" {
  type        = string
  default     = ""
  description = "The name of the AWS profile configured in the AWS credentials file (typically located at ~/.aws/credentials). This profile contains the access key, secret key, and optional session token associated with the shared-vpc AWS account."
}

variable "cluster_owner_aws_shared_credentials_files" {
  type        = list(string)
  default     = null
  description = "List of files path to the AWS shared credentials file. This file typically contains AWS access keys and secret keys and is used when authenticating with AWS using profiles (default file located at ~/.aws/credentials)."
}

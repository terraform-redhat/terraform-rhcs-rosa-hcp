output "cluster_id" {
  value       = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.id
  description = "The identification of the cluster in OCM"
}

output "cluster_admin_username" {
  value       = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.admin_credentials == null ? null : rhcs_cluster_rosa_hcp.rosa_hcp_cluster.admin_credentials.username
  description = "The username of the admin user."
}

output "cluster_admin_password" {
  value       = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.admin_credentials == null ? null : rhcs_cluster_rosa_hcp.rosa_hcp_cluster.admin_credentials.password
  description = "The password of the admin user."
  sensitive   = true
}

output "cluster_api_url" {
  value       = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.api_url
  description = "The URL of the API server."
}

output "cluster_console_url" {
  value       = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.console_url
  description = "The URL of the console."
}

output "cluster_domain" {
  value       = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.domain
  description = "The DNS domain of cluster."
}

output "cluster_current_version" {
  value       = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.current_version
  description = "The currently running version of OpenShift on the cluster, for example '4.11.0'."
}

output "cluster_state" {
  value       = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.state
  description = "The state of the cluster."
}

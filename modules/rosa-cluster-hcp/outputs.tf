output "cluster_id" {
  value = rhcs_cluster_rosa_hcp.rosa_hcp_cluster.id
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
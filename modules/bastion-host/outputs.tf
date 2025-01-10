output "bastion_host_public_ip" {
  description = "Bastion Host Public IP"
  value       = jsondecode(time_sleep.bastion_resources_wait.triggers["public_ips"])
}

output "bastion_host_pem_path" {
  description = "File path of bastion host .pem"
  value       = time_sleep.bastion_resources_wait.triggers["pem_path"]
}

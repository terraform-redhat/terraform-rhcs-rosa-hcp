output "bastion_host_public_ip" {
  description = "Bastion Host Public IP"
  value       = jsondecode(time_sleep.bastion_resources_wait.triggers["public_ips"])
}

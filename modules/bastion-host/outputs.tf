output "bastion_host_public_ip" {
  description = "Bastion Host Public IP"
  value       = [for value in aws_instance.bastion_host : value.public_ip]
}

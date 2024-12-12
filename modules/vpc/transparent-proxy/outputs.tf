# Outputs
output "proxy_public_ip" {
  value = aws_instance.proxy.public_ip
}

output "proxy_network_interface_id" {
  value = aws_instance.proxy.primary_network_interface_id
}

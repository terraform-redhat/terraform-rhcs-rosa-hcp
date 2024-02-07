output "private_subnets" {
  value = aws_subnet.private[*].id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "availability_zones" {
  value = slice(data.aws_availability_zones.available.names, 0, var.subnet_count)
}

output "vpc_id" {
  value = aws_vpc.site.id
}

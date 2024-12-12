locals {
  tags               = var.tags == null ? {} : var.tags
  availability_zones = var.availability_zones != null ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, var.availability_zones_count)
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    {
      "Name" = "${var.name_prefix}-vpc"
    },
    local.tags,
  )
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_subnet" "public_subnet" {
  count = length(local.availability_zones)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, length(local.availability_zones) * 2, count.index)
  availability_zone = local.availability_zones[count.index]
  tags = merge(
    {
      "Name"                   = join("-", [var.name_prefix, "subnet", "public${count.index + 1}", local.availability_zones[count.index]])
      "kubernetes.io/role/elb" = ""
    },
    local.tags,
  )
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_subnet" "private_subnet" {
  count = length(local.availability_zones)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, length(local.availability_zones) * 2, count.index + length(local.availability_zones))
  availability_zone = local.availability_zones[count.index]
  tags = merge(
    {
      "Name"                            = join("-", [var.name_prefix, "subnet", "private${count.index + 1}", local.availability_zones[count.index]])
      "kubernetes.io/role/internal-elb" = ""
    },
    local.tags,
  )
  lifecycle {
    ignore_changes = [tags]
  }
}

#########################
# ZERO EGRESS SUPPORT
#########################
module "zero_egress" {
  count       = var.is_zero_egress ? 1 : 0
  source      = "./zero-egress"
  vpc_id      = aws_vpc.vpc.id
  subnet_ids  = [for subnet in aws_subnet.private_subnet[*] : subnet.id]
  cidr_blocks = [for subnet in aws_subnet.private_subnet[*] : subnet.cidr_block]
}

#########################
# Transparent Proxy Support
#########################
data "aws_ami" "rhel9" {
  most_recent = true

  filter {
    name   = "platform-details"
    values = ["Red Hat Enterprise Linux"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "manifest-location"
    values = ["amazon/RHEL-9.*_HVM-*-x86_64-*-Hourly2-GP2"]
  }

  owners = ["309956199498"] # Amazon's "Official Red Hat" account
}
module "transparent-proxy" {
  count  = var.enable_transparent_proxy ? 1 : 0
  source = "./transparent-proxy"
  ami_id = data.aws_ami.rhel9.id
  prefix = var.name_prefix

  subnet_id      = aws_subnet.public_subnet[0].id
  vpc_id         = aws_vpc.vpc.id
  user_data_file = var.proxy_user_data_file
}

#
# Internet gateway
#
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    {
      "Name" = "${var.name_prefix}-igw"
    },
    local.tags,
  )
  lifecycle {
    ignore_changes = [tags]
  }
}

#
# Elastic IPs for NAT gateways
#
resource "aws_eip" "eip" {
  count = var.is_zero_egress ? 0 : length(local.availability_zones)

  domain = "vpc"
  tags = merge(
    {
      "Name" = join("-", [var.name_prefix, "eip", local.availability_zones[count.index]])
    },
    local.tags,
  )
  lifecycle {
    ignore_changes = [tags]
  }
}

#
# NAT gateways
#
resource "aws_nat_gateway" "public_nat_gateway" {
  count = var.is_zero_egress ? 0 : length(local.availability_zones)

  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id

  tags = merge(
    {
      "Name" = join("-", [var.name_prefix, "nat", "public${count.index}", local.availability_zones[count.index]])
    },
    local.tags,
  )
  lifecycle {
    ignore_changes = [tags]
  }
}

#
# Route tables
#
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    {
      "Name" = "${var.name_prefix}-public"
    },
    local.tags,
  )
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_eip" "escape_nat_eip" {
  count      = var.is_zero_egress ? 0 : 1
  domain     = "vpc"
  tags       = { Name = "${var.name_prefix}-escape-nat-eip" }
  depends_on = [aws_internet_gateway.internet_gateway]
}
resource "aws_nat_gateway" "escape_nat_gw" {
  count         = var.is_zero_egress ? 0 : 1
  allocation_id = aws_eip.escape_nat_eip[0].id
  subnet_id     = aws_subnet.public_subnet[0].id
  tags          = { Name = "${var.name_prefix}-escape-nat-gw" }
  depends_on    = [aws_internet_gateway.internet_gateway]
}

resource "aws_route_table" "private_route_table" {
  count = length(local.availability_zones)

  vpc_id = aws_vpc.vpc.id
  tags = merge(
    {
      "Name" = join("-", [var.name_prefix, "rtb", "private${count.index}", local.availability_zones[count.index]])
    },
    local.tags,
  )
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = var.enable_transparent_proxy ? module.transparent-proxy[0].proxy_network_interface_id : null
  }
  dynamic "route" {
    for_each = var.is_zero_egress ? null : toset([for subnet in aws_subnet.private_subnet[*] : subnet.cidr_block] )
    content {
      cidr_block = route.value
      gateway_id = aws_nat_gateway.escape_nat_gw[0].id
    }
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.is_zero_egress ? [for rt in aws_route_table.private_route_table[*] : rt.id] : []
}

#
# Routes
#
# Send all IPv4 traffic to the internet gateway
resource "aws_route" "ipv4_egress_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
  depends_on             = [aws_route_table.public_route_table]
}

# Send all IPv6 traffic to the internet gateway
resource "aws_route" "ipv6_egress_route" {
  route_table_id              = aws_route_table.public_route_table.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.internet_gateway.id
  depends_on                  = [aws_route_table.public_route_table]
}

# Send private traffic to NAT
resource "aws_route" "private_nat" {
  count = (var.is_zero_egress || var.enable_transparent_proxy) ? 0 : length(local.availability_zones)

  route_table_id         = aws_route_table.private_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.public_nat_gateway[count.index].id
  depends_on             = [aws_route_table.private_route_table, aws_nat_gateway.public_nat_gateway]
}


# Private route for vpc endpoint
resource "aws_vpc_endpoint_route_table_association" "private_vpc_endpoint_route_table_association" {
  count = length(local.availability_zones)

  route_table_id  = aws_route_table.private_route_table[count.index].id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

#
# Route table associations
#
resource "aws_route_table_association" "public_route_table_association" {
  count = length(local.availability_zones)

  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_route_table_association" {
  count = length(local.availability_zones)

  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}

# This resource is used in order to add dependencies on all resources 
# Any resource uses this VPC ID, must wait to all resources creation completion
resource "time_sleep" "vpc_resources_wait" {
  create_duration  = "20s"
  destroy_duration = "20s"
  triggers = {
    vpc_id                                           = aws_vpc.vpc.id
    cidr_block                                       = aws_vpc.vpc.cidr_block
    ipv4_egress_route_id                             = aws_route.ipv4_egress_route.id
    ipv6_egress_route_id                             = aws_route.ipv6_egress_route.id
    private_nat_ids                                  = (var.is_zero_egress || var.enable_transparent_proxy) ? jsonencode([]) : jsonencode([for value in aws_route.private_nat : value.id])
    private_vpc_endpoint_route_table_association_ids = jsonencode([for value in aws_vpc_endpoint_route_table_association.private_vpc_endpoint_route_table_association : value.id])
    public_route_table_association_ids               = jsonencode([for value in aws_route_table_association.public_route_table_association : value.id])
    private_route_table_association_ids              = jsonencode([for value in aws_route_table_association.private_route_table_association : value.id])
  }
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"

  # New configuration to exclude Local Zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

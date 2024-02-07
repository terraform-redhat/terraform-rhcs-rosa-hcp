resource "aws_vpc" "site" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    {
      "Name" = "${var.name_prefix}-vpc"
    },
    var.tags,
  )
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.site.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
}

resource "aws_subnet" "public" {
  count = var.subnet_count

  vpc_id            = aws_vpc.site.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.subnet_count * 2, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  tags = merge(
    {
      "Name" = join("-", [var.name_prefix, "subnet", "public${count.index + 1}", data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]]),
      "kubernetes.io/role/elb" = ""
    },
    var.tags,
  )
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_subnet" "private" {
  count = var.subnet_count

  vpc_id            = aws_vpc.site.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.subnet_count * 2, count.index + var.subnet_count)
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  tags = merge(
    {
      "Name" = join("-", [var.name_prefix, "subnet", "private${count.index + 1}", data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]])
      "kubernetes.io/role/internal-elb" = ""
    },
    var.tags,
  )
  lifecycle {
    ignore_changes = [tags]
  }
}


#
# Internet gateway
#
resource "aws_internet_gateway" "site" {
  vpc_id = aws_vpc.site.id
  tags = merge(
    {
      "Name" = "${var.name_prefix}-igw"
    },
    var.tags,
  )
  lifecycle {
    ignore_changes = [tags]
  }
}

#
# Elastic IPs for NAT gateways
#
resource "aws_eip" "nat" {
  count = var.subnet_count

  domain = "vpc"
  tags = merge(
    {
      "Name" = join("-", [var.name_prefix, "eip", data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]])
    },
    var.tags,
  )
  lifecycle {
    ignore_changes = [tags]
  }
}


#
# NAT gateways
#
resource "aws_nat_gateway" "public" {
  count = var.subnet_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    {
      "Name" = join("-", [var.name_prefix, "nat", "public${count.index}", data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]])
    },
    var.tags,
  )
  lifecycle {
    ignore_changes = [tags]
  }
}

#
# Route tables
#
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.site.id
  tags = merge(
    {
      "Name" = "${var.name_prefix}-public"
    },
    var.tags,
  )
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_route_table" "private" {
  count = var.subnet_count

  vpc_id = aws_vpc.site.id
  tags = merge(
    {
      "Name" = join("-", [var.name_prefix, "rtb", "private${count.index}", data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]])
    },
    var.tags,
  )
  lifecycle {
    ignore_changes = [tags]
  }
}

#
# Routes
#
# Send all IPv4 traffic to the internet gateway
resource "aws_route" "ipv4_egress_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.site.id
  depends_on             = [aws_route_table.public]
}

# Send all IPv6 traffic to the internet gateway
resource "aws_route" "ipv6_egress_route" {
  route_table_id              = aws_route_table.public.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.site.id
  depends_on                  = [aws_route_table.public]
}

# Send private traffic to NAT
resource "aws_route" "private_nat" {
  count = var.subnet_count

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.public[count.index].id
  depends_on             = [aws_route_table.private, aws_nat_gateway.public]
}


# Private route for vpc endpoint
resource "aws_vpc_endpoint_route_table_association" "private" {
  count = var.subnet_count

  route_table_id  = aws_route_table.private[count.index].id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

#
# Route table associations
#
resource "aws_route_table_association" "public" {
  count = var.subnet_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = var.subnet_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
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

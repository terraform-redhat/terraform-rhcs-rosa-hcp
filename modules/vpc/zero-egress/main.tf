data "aws_region" "current" {}

resource "aws_security_group" "authorize_inbound_vpc_traffic" {
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.cidr_blocks
  }
  vpc_id = var.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_vpc_endpoint" "sts" {
  service_name      = "com.amazonaws.${data.aws_region.current.name}.sts"
  vpc_id            = var.vpc_id
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.authorize_inbound_vpc_traffic.id]
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_id            = var.vpc_id
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.authorize_inbound_vpc_traffic.id]
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_id            = var.vpc_id
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.authorize_inbound_vpc_traffic.id]
  lifecycle {
    ignore_changes = [tags]
  }
}

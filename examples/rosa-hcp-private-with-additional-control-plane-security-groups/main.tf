locals {
  account_role_prefix  = "${var.cluster_name}-account"
  operator_role_prefix = "${var.cluster_name}-operator"
}

############################
# Additional Security Groups
############################
resource "aws_security_group" "sg1" {
  name        = "${var.cluster_name}-sg1"
  description = "Additional SG 1"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${var.cluster_name}-sg1"
  }
}
resource "aws_vpc_security_group_ingress_rule" "sg1" {
  security_group_id = aws_security_group.sg1.id
  cidr_ipv4         = "172.16.0.0/16"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_security_group" "sg2" {
  name        = "${var.cluster_name}-sg2"
  description = "Additional SG 2"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${var.cluster_name}-sg2"
  }
}
resource "aws_vpc_security_group_ingress_rule" "sg2" {
  security_group_id = aws_security_group.sg2.id
  cidr_ipv4         = "192.168.0.0/16"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

locals {
  additional_sg_ids = [
    aws_security_group.sg1.id,
    aws_security_group.sg2.id,
  ]
}

############################
# Cluster
############################
module "hcp" {
  source = "../../"

  cluster_name                                    = var.cluster_name
  openshift_version                               = var.openshift_version
  machine_cidr                                    = module.vpc.cidr_block
  aws_subnet_ids                                  = module.vpc.private_subnets
  replicas                                        = 2
  private                                         = true
  create_admin_user                               = true
  admin_credentials_username                      = "admin"
  admin_credentials_password                      = random_password.password.result
  ec2_metadata_http_tokens                        = "required"
  aws_additional_control_plane_security_group_ids = local.additional_sg_ids

  // STS configuration
  create_account_roles  = true
  account_role_prefix   = local.account_role_prefix
  create_oidc           = true
  create_operator_roles = true
  operator_role_prefix  = local.operator_role_prefix
}

resource "random_password" "password" {
  length      = 14
  special     = true
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

############################
# VPC
############################
module "vpc" {
  source = "../../modules/vpc"

  name_prefix              = var.cluster_name
  availability_zones_count = 1
}

############################
# Bastion instance for connection to the cluster
############################
module "bastion_host" {
  source     = "../../modules/bastion-host"
  prefix     = var.cluster_name
  vpc_id     = module.vpc.vpc_id
  subnet_ids = [module.vpc.public_subnets[0]]
}

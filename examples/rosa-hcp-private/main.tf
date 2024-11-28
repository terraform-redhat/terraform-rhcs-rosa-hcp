locals {
  account_role_prefix  = "${var.cluster_name}-account"
  operator_role_prefix = "${var.cluster_name}-operator"
}

############################
# Cluster
############################
module "hcp" {
  source = "../../"

  cluster_name             = var.cluster_name
  openshift_version        = var.openshift_version
  machine_cidr             = module.vpc.cidr_block
  aws_subnet_ids           = module.vpc.private_subnets
  replicas                 = length(module.vpc.availability_zones)
  private                  = true
  create_admin_user        = true
  ec2_metadata_http_tokens = "required"

  // STS configuration
  create_account_roles  = true
  account_role_prefix   = local.account_role_prefix
  create_oidc           = true
  create_operator_roles = true
  operator_role_prefix  = local.operator_role_prefix
}

############################
# HTPASSWD IDP
############################
module "htpasswd_idp" {
  source = "../../modules/idp"

  cluster_id         = module.hcp.cluster_id
  name               = "htpasswd-idp"
  idp_type           = "htpasswd"
  htpasswd_idp_users = [{ username = "test-user", password = random_password.password.result }]
}

resource "random_password" "password" {
  length  = 14
  special = true
  min_lower = 1
  min_numeric = 1
  min_special = 1
  min_upper = 1
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
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "bastion_ssh_key" {
  provider   = aws.network-owner
  key_name   = "${var.cluster_name}-bastion-ssh-key"
  public_key = tls_private_key.pk.public_key_openssh
}

resource "local_file" "bastion_private_ssh_key" {
  filename        = "${aws_key_pair.bastion_ssh_key.key_name}.pem"
  content         = tls_private_key.pk.private_key_pem
  file_permission = 0400
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

resource "aws_security_group" "bastion_host_ingress" {
  provider = aws.network-owner
  name     = "${var.cluster_name}-bastion-security-group"
  vpc_id   = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "bastion_host" {
  provider                    = aws.network-owner
  ami                         = "ami-004130e0a96e1f4df"
  instance_type               = "t2.micro"
  key_name                    = "${var.cluster_name}-bastion-ssh-key"
  security_groups             = [aws_security_group.bastion_host_ingress.id]
  for_each                    = toset(module.vpc.public_subnets)
  subnet_id                   = each.value
  associate_public_ip_address = true
  tags = {
    Name = "${var.cluster_name}-bastion-host"
  }
}

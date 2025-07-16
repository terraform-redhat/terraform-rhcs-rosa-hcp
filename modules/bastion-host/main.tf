resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion_ssh_key" {
  key_name   = "${var.prefix}-bastion-ssh-key"
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
  name   = "${var.prefix}-bastion-security-group"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = concat(["${chomp(data.http.myip.response_body)}/32"], var.cidr_blocks == null ? [] : var.cidr_blocks)
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

data "aws_ami" "rhel9" {
  count       = var.ami_id == null ? 1 : 0
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

resource "aws_instance" "bastion_host" {
  count                       = length(var.subnet_ids)
  ami                         = var.ami_id != null ? var.ami_id : data.aws_ami.rhel9[0].id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.bastion_ssh_key.key_name
  vpc_security_group_ids      = [aws_security_group.bastion_host_ingress.id]
  subnet_id                   = var.subnet_ids[count.index]
  associate_public_ip_address = true

  user_data                   = var.user_data_file != null ? var.user_data_file : file("${path.module}/../../assets/bastion-host-user-data.yaml")
  user_data_replace_on_change = true
  tags = {
    Name = "${var.prefix}-bastion-host"
  }
}

resource "time_sleep" "bastion_resources_wait" {
  create_duration  = "20s"
  destroy_duration = "20s"
  triggers = {
    public_ips = jsonencode([for value in aws_instance.bastion_host : value.public_ip])
    pem_path   = local_file.bastion_private_ssh_key.filename
  }
}

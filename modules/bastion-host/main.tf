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
  count = var.cidr_blocks == null ? 1 : 0
  url   = "https://ipv4.icanhazip.com"
}

resource "aws_security_group" "bastion_host_ingress" {
  name   = "${var.prefix}-bastion-security-group"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks == null ? ["${chomp(data.http.myip[0].response_body)}/32"] : var.cidr_blocks
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
  count                       = length(var.subnet_ids)
  ami                         = var.ami_id != null ? var.ami_id : "ami-004130e0a96e1f4df"
  instance_type               = var.instance_type != null ? var.instance_type : "t2.micro"
  key_name                    = "${var.prefix}-bastion-ssh-key"
  security_groups             = [aws_security_group.bastion_host_ingress.id]
  subnet_id                   = var.subnet_ids[count.index]
  associate_public_ip_address = true
  tags = {
    Name = "${var.prefix}-bastion-host"
  }
}
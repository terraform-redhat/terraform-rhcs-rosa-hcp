resource "tls_private_key" "proxy_pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "proxy_ssh_key" {
  key_name   = "${var.prefix}-proxy-ssh-key"
  public_key = tls_private_key.proxy_pk.public_key_openssh
}

resource "local_file" "proxy_private_ssh_key" {
  filename        = "${aws_key_pair.proxy_ssh_key.key_name}.pem"
  content         = tls_private_key.proxy_pk.private_key_pem
  file_permission = 0400
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

resource "aws_security_group" "proxy_host_ingress" {
  name   = "${var.prefix}-proxy-security-group"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = concat(["${chomp(data.http.myip[0].response_body)}/32"], var.cidr_blocks == null ? [] : var.cidr_blocks)
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "proxy" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.proxy_ssh_key.key_name
  security_groups             = [aws_security_group.proxy_host_ingress.id]
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true

  source_dest_check           = false
  user_data                   = var.user_data_file
  user_data_replace_on_change = true
  tags = {
    Name = "${var.prefix}-proxy-host"
  }
}

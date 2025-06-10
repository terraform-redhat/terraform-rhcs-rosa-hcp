#### Ingress hosted zone
resource "aws_route53_zone" "ingress_private_hosted_zone" {
  name = "rosa.${var.cluster_name}.${var.ingress_private_hosted_zone_base_domain}"

  vpc {
    vpc_id = var.vpc_id
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

#### HCP Internal Communication hosted zone
resource "aws_route53_zone" "hcp_internal_communication_hosted_zone" {
  name = "${var.cluster_name}.hypershift.local"

  vpc {
    vpc_id = var.vpc_id
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_route53_vpc_association_authorization" "ingress_hz_association_auth" {
  count   = var.create_association_authorization ? 1 : 0
  vpc_id  = var.secondary_vpc_id
  zone_id = aws_route53_zone.ingress_private_hosted_zone.id
}

resource "aws_route53_vpc_association_authorization" "hcp_internal_comm_hz_association_auth" {
  count   = var.create_association_authorization ? 1 : 0
  vpc_id  = var.secondary_vpc_id
  zone_id = aws_route53_zone.hcp_internal_communication_hosted_zone.id
}

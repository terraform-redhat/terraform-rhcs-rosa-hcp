data "aws_subnet" "aws_subnet_ids" {
  id = var.aws_subnet_ids
}

data "aws_vpc_endpoint" "control_plane" {
  vpc_id = data.aws_subnet.vpc_subnet.vpc_id
  filter {
    name   = "tag:api.openshift.com/id"
    values = [var.cluster_id]
  }
}

resource "aws_vpc_endpoint_security_group_association" "control_plane_sg" {
  for_each          = var.aws_additional_control_plane_security_group_ids
  vpc_endpoint_id   = data.aws_vpc_endpoint.control_plane.id
  security_group_id = each.value
}
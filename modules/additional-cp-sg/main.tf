data "aws_subnet" "aws_subnet_id" {
  id = var.aws_subnet_id
}

data "aws_vpc_endpoint" "control_plane" {
  vpc_id = data.aws_subnet.aws_subnet_id.vpc_id
  filter {
    name   = "tag:api.openshift.com/id"
    values = [var.cluster_id]
  }
}

resource "aws_vpc_endpoint_security_group_association" "control_plane_sg" {
  count             = length(var.aws_additional_control_plane_security_group_ids)
  vpc_endpoint_id   = data.aws_vpc_endpoint.control_plane.id
  security_group_id = var.aws_additional_control_plane_security_group_ids[count.index]
}
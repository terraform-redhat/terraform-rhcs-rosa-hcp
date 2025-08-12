locals {
  resource_arn_prefix = "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:subnet/"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

resource "aws_ram_resource_share" "shared_vpc_resource_share" {
  name                      = "${var.name_prefix}-shared-vpc-resource-share"
  allow_external_principals = true
}

resource "aws_ram_principal_association" "shared_vpc_resource_share" {
  principal          = var.target_aws_account
  resource_share_arn = aws_ram_resource_share.shared_vpc_resource_share.arn
}

resource "aws_ram_resource_association" "shared_vpc_resource_association" {
  count = length(var.subnets)

  resource_arn       = "${local.resource_arn_prefix}${var.subnets[count.index]}"
  resource_share_arn = aws_ram_principal_association.shared_vpc_resource_share.resource_share_arn
}

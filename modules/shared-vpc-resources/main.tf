locals {
  resource_arn_prefix     = "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:subnet/"
  account_roles_prefix    = var.account_roles_prefix
  installer_role_name     = substr("${local.account_roles_prefix}-HCP-ROSA-Installer-Role", 0, 64)
  installer_role_arn      = "arn:aws:iam::${var.target_aws_account}:role/${local.installer_role_name}"
  operator_roles_prefix   = var.operator_roles_prefix
  ingress_role_name       = substr("${local.operator_roles_prefix}-openshift-ingress-operator-cloud-credentials", 0, 64)
  ingress_role_arn        = "arn:aws:iam::${var.target_aws_account}:role/${local.ingress_role_name}"
  control_plane_role_name = substr("${local.operator_roles_prefix}-kube-system-control-plane-operator", 0, 64)
  control_plane_role_arn  = "arn:aws:iam::${var.target_aws_account}:role/${local.control_plane_role_name}"
}

### Roles
#### Route 53 role
resource "aws_iam_role" "route53_role" {
  name = substr("${var.name_prefix}-shared-route53-role", 0, 64)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "BeAssumableFrom"
        Principal = {
          AWS = [
            local.installer_role_arn,
            local.control_plane_role_arn,
            local.ingress_role_arn,
          ]
        }
      }
    ]
  })
  description = "Role that managed Route 53 and will be assumed from the Target AWS account where the cluster resides"
}

resource "aws_iam_policy" "route53_policy" {
  name = substr("${var.name_prefix}-shared-route53-policy", 0, 64)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "ReadPermissions",
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:DescribeLoadBalancers",
          "route53:GetHostedZone",
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "tag:GetResources"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "ChangeResourceRecordSetsRestrictedRecordNames",
        "Effect" : "Allow",
        "Action" : [
          "route53:ChangeResourceRecordSets"
        ],
        "Resource" : [
          "*"
        ],
        "Condition" : {
          "ForAllValues:StringLike" : {
            "route53:ChangeResourceRecordSetsNormalizedRecordNames" : [
              "*.hypershift.local",
              "*.openshiftapps.com",
              "*.devshift.org",
              "*.openshiftusgov.com",
              "*.devshiftusgov.com"
            ]
          }
        }
      },
      {
        "Sid" : "ChangeTagsForResourceNoCondition",
        "Effect" : "Allow",
        "Action" : [
          "route53:ChangeTagsForResource"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "route_53_role_policy_attachment" {
  role       = aws_iam_role.route53_role.name
  policy_arn = aws_iam_policy.route53_policy.arn
}

### VPCE role
resource "aws_iam_role" "vpce_role" {
  name = substr("${var.name_prefix}-shared-vpce-role", 0, 64)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "BeAssumableFrom"
        Principal = {
          AWS = [
            local.installer_role_arn,
            local.control_plane_role_arn
          ]
        }
      }
    ]
  })
  description = "Role that manages VPC Endpoint and will be assumed from the Target AWS account where the cluster resides"
}

resource "aws_iam_policy" "vpce_policy" {
  name = substr("${var.name_prefix}-shared-vpce-policy", 0, 64)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "ReadPermissions",
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeVpcEndpoints",
          "ec2:DescribeVpcs",
          "ec2:DescribeSecurityGroups"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "CreateSecurityGroups",
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateSecurityGroup"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:security-group*/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:RequestTag/red-hat-managed" : "true"
          }
        }
      },
      {
        "Sid" : "DeleteSecurityGroup",
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteSecurityGroup"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:security-group*/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/red-hat-managed" : "true"
          }
        }
      },
      {
        "Sid" : "SecurityGroupIngressEgress",
        "Effect" : "Allow",
        "Action" : [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:security-group*/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/red-hat-managed" : "true"
          }
        }
      },
      {
        "Sid" : "CreateSecurityGroupsVPCNoCondition",
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateSecurityGroup"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:vpc/*"
        ]
      },
      {
        "Sid" : "VPCEndpointWithCondition",
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateVpcEndpoint"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:vpc-endpoint/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:RequestTag/red-hat-managed" : "true"
          }
        }
      },
      {
        "Sid" : "VPCEndpointResourceTagCondition",
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateVpcEndpoint"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:security-group*/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/red-hat-managed" : "true"
          }
        }
      },
      {
        "Sid" : "VPCEndpointNoCondition",
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateVpcEndpoint"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:vpc/*",
          "arn:aws:ec2:*:*:subnet/*",
          "arn:aws:ec2:*:*:route-table/*"
        ]
      },
      {
        "Sid" : "ManageVPCEndpointWithCondition",
        "Effect" : "Allow",
        "Action" : [
          "ec2:ModifyVpcEndpoint",
          "ec2:DeleteVpcEndpoints"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:vpc-endpoint/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/red-hat-managed" : "true"
          }
        }
      },
      {
        "Sid" : "ModifyVPCEndpoingNoCondition",
        "Effect" : "Allow",
        "Action" : [
          "ec2:ModifyVpcEndpoint"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:subnet/*"
        ]
      },
      {
        "Sid" : "CreateTagsRestrictedActions",
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateTags"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:vpc-endpoint/*",
          "arn:aws:ec2:*:*:security-group/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "ec2:CreateAction" : [
              "CreateVpcEndpoint",
              "CreateSecurityGroup"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vpce_role_policy_attachment" {
  role       = aws_iam_role.vpce_role.name
  policy_arn = aws_iam_policy.vpce_policy.arn
}

### Subnet share
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
  resource_share_arn = aws_ram_resource_share.shared_vpc_resource_share.arn
}

### Hosted zones
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

# This resource is utilized to establish dependencies on all resources.
# Some resources, such as aws_ram_principle_associasion, may not have their output utilized, but they are crucial for the cluster.
# Hence, the creation of these resources must be finalized prior to the initiation of cluster creation, and they should not be removed before the cluster is destroyed.
resource "time_sleep" "shared_resources_propagation" {
  destroy_duration = "20s"
  create_duration  = "20s"

  triggers = {
    route53_role_arn                                  = aws_iam_role.route53_role.arn
    route53_policy_arn                                = aws_iam_role_policy_attachment.route_53_role_policy_attachment.policy_arn
    vpce_role_arn                                     = aws_iam_role.vpce_role.arn
    vpce_policy_arn                                   = aws_iam_role_policy_attachment.vpce_role_policy_attachment.policy_arn
    ingress_private_hosted_zone_id                    = aws_route53_zone.ingress_private_hosted_zone.id
    hcp_internal_communication_private_hosted_zone_id = aws_route53_zone.hcp_internal_communication_hosted_zone.id
    resource_share_arn                                = aws_ram_principal_association.shared_vpc_resource_share.resource_share_arn
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}
provider "aws" {
  alias = "cluster-owner"

  access_key               = var.cluster_owner_aws_access_key_id
  secret_key               = var.cluster_owner_aws_secret_access_key
  region                   = data.aws_region.current.name
  profile                  = var.cluster_owner_aws_profile
  shared_credentials_files = var.cluster_owner_aws_shared_credentials_files
}

data "aws_partition" "cluster_owner" {
  provider = aws.cluster-owner
}

data "aws_caller_identity" "cluster_owner" {
  provider = aws.cluster-owner
}

provider "aws" {
  alias = "network-owner"

  access_key               = var.network_owner_aws_access_key_id
  secret_key               = var.network_owner_aws_secret_access_key
  region                   = data.aws_region.current.name
  profile                  = var.network_owner_aws_profile
  shared_credentials_files = var.network_owner_aws_shared_credentials_files
}

data "aws_partition" "network_owner" {
  provider = aws.network-owner
}

data "aws_caller_identity" "network_owner" {
  provider = aws.network-owner
}

locals {
  account_role_prefix          = "${var.cluster_name}-acc"
  operator_role_prefix         = "${var.cluster_name}-op"
  shared_resources_name_prefix = var.cluster_name
  shared_route53_role_name     = substr("${local.shared_resources_name_prefix}-shared-route53-role", 0, 64)
  shared_vpce_role_name        = substr("${local.shared_resources_name_prefix}-shared-vpce-role", 0, 64)
  # Required to generate the expected names for the shared vpc role arns
  # There is a cyclic dependency on the shared vpc role arns and the installer,control-plane,ingress roles
  # that is because AWS will not accept to include these into the trust policy without first creating it
  # however, will allow to generate a permission policy with these values before the creation of the roles
  shared_vpc_roles_arns = {
    "route53" : "arn:${data.aws_partition.cluster_owner.partition}:iam::${data.aws_caller_identity.cluster_owner.account_id}:role/${local.shared_route53_role_name}",
    "vpce" : "arn:${data.aws_partition.network_owner.partition}:iam::${data.aws_caller_identity.network_owner.account_id}:role/${local.shared_vpce_role_name}"
  }
}

##############################################################
# Account roles includes IAM roles and IAM policies
##############################################################
module "account_iam_resources" {
  source = "../../modules/account-iam-resources"
  providers = {
    aws = aws.cluster-owner
  }

  account_role_prefix        = local.account_role_prefix
  create_shared_vpc_policies = true
  shared_vpc_roles           = local.shared_vpc_roles_arns
}

############################
# OIDC provider
############################
module "oidc_config_and_provider" {
  source = "../../modules/oidc-config-and-provider"
  providers = {
    aws = aws.cluster-owner
  }

  managed = true
}

############################
# operator roles
############################
module "operator_roles" {
  source = "../../modules/operator-roles"
  providers = {
    aws = aws.cluster-owner
  }

  operator_role_prefix       = local.operator_role_prefix
  path                       = module.account_iam_resources.path
  oidc_endpoint_url          = module.oidc_config_and_provider.oidc_endpoint_url
  create_shared_vpc_policies = false
  shared_vpc_roles           = local.shared_vpc_roles_arns
}

resource "rhcs_dns_domain" "dns_domain" {
  cluster_arch = "hcp"
}

############################
# shared-vpc-resources
############################
module "vpc" {
  source = "../../modules/vpc"

  providers = {
    aws = aws.network-owner
  }

  name_prefix              = local.shared_resources_name_prefix
  availability_zones_count = 1
}

locals {
  resource_arn_prefix     = "arn:${data.aws_partition.network_owner.partition}:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.network_owner.account_id}:subnet/"
  installer_role_name     = substr("${local.account_role_prefix}-HCP-ROSA-Installer-Role", 0, 64)
  installer_role_arn      = "arn:aws:iam::${data.aws_caller_identity.cluster_owner.account_id}:role/${local.installer_role_name}"
  ingress_role_name       = substr("${local.operator_role_prefix}-openshift-ingress-operator-cloud-credentials", 0, 64)
  ingress_role_arn        = "arn:aws:iam::${data.aws_caller_identity.cluster_owner.account_id}:role/${local.ingress_role_name}"
  control_plane_role_name = substr("${local.operator_role_prefix}-kube-system-control-plane-operator", 0, 64)
  control_plane_role_arn  = "arn:aws:iam::${data.aws_caller_identity.cluster_owner.account_id}:role/${local.control_plane_role_name}"
}

### Roles
#### Route 53 role
resource "aws_iam_role" "route53_role" {
  provider = aws.cluster-owner
  name     = substr("${local.shared_resources_name_prefix}-shared-route53-role", 0, 64)
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
  provider = aws.cluster-owner
  name     = substr("${local.shared_resources_name_prefix}-shared-route53-policy", 0, 64)
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
  provider   = aws.cluster-owner
  role       = aws_iam_role.route53_role.name
  policy_arn = aws_iam_policy.route53_policy.arn
}

### VPCE role
resource "aws_iam_role" "vpce_role" {
  provider = aws.network-owner
  name     = substr("${local.shared_resources_name_prefix}-shared-vpce-role", 0, 64)
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
  provider = aws.network-owner
  name     = substr("${local.shared_resources_name_prefix}-shared-vpce-policy", 0, 64)
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
  provider   = aws.network-owner
  role       = aws_iam_role.vpce_role.name
  policy_arn = aws_iam_policy.vpce_policy.arn
}

### Subnet share
resource "aws_ram_resource_share" "shared_vpc_resource_share" {
  provider                  = aws.network-owner
  name                      = "${local.shared_resources_name_prefix}-shared-vpc-resource-share"
  allow_external_principals = true
}

resource "aws_ram_principal_association" "shared_vpc_resource_share" {
  provider           = aws.network-owner
  principal          = data.aws_caller_identity.cluster_owner.account_id
  resource_share_arn = aws_ram_resource_share.shared_vpc_resource_share.arn
}

resource "aws_ram_resource_association" "shared_vpc_resource_association" {
  provider = aws.network-owner
  count    = length(module.vpc.private_subnets)

  resource_arn       = "${local.resource_arn_prefix}${module.vpc.private_subnets[count.index]}"
  resource_share_arn = aws_ram_resource_share.shared_vpc_resource_share.arn
}

### Hosted zones
# Hosted zone association authorization requires first
# that the hosted zone exists and is associated with a vpc in the cluster owner account
module "cluster_owner_vpc" {
  source = "../../modules/vpc"

  providers = {
    aws = aws.cluster-owner
  }

  name_prefix              = local.shared_resources_name_prefix
  availability_zones_count = 1
}
#### Ingress hosted zone
resource "aws_route53_zone" "ingress_private_hosted_zone" {
  provider = aws.cluster-owner
  name     = "rosa.${var.cluster_name}.${rhcs_dns_domain.dns_domain.id}"

  vpc {
    vpc_id = module.cluster_owner_vpc.vpc_id
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_route53_vpc_association_authorization" "ingress_private_hosted_zone_association_auth" {
  provider = aws.cluster-owner
  vpc_id   = module.vpc.vpc_id
  zone_id  = aws_route53_zone.ingress_private_hosted_zone.id
}

resource "aws_route53_zone_association" "ingress_private_hosted_zone_association" {
  provider = aws.network-owner

  vpc_id  = aws_route53_vpc_association_authorization.ingress_private_hosted_zone_association_auth.vpc_id
  zone_id = aws_route53_vpc_association_authorization.ingress_private_hosted_zone_association_auth.zone_id
}

#### HCP Internal Communication hosted zone
resource "aws_route53_zone" "hcp_internal_communication_hosted_zone" {
  provider = aws.cluster-owner
  name     = "${var.cluster_name}.hypershift.local"

  vpc {
    vpc_id = module.cluster_owner_vpc.vpc_id
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_route53_vpc_association_authorization" "hcp_internal_communication_hosted_zone_association_auth" {
  provider = aws.cluster-owner
  vpc_id   = module.vpc.vpc_id
  zone_id  = aws_route53_zone.hcp_internal_communication_hosted_zone.id
}

resource "aws_route53_zone_association" "hcp_internal_communication_hosted_zone_association" {
  provider = aws.network-owner

  vpc_id  = aws_route53_vpc_association_authorization.hcp_internal_communication_hosted_zone_association_auth.vpc_id
  zone_id = aws_route53_vpc_association_authorization.hcp_internal_communication_hosted_zone_association_auth.zone_id
}

resource "time_sleep" "shared_resources_propagation" {
  destroy_duration = "20s"
  create_duration  = "20s"

  triggers = {
    route53_role_arn                                  = aws_iam_role.route53_role.arn
    route53_policy_arn                                = aws_iam_role_policy_attachment.route_53_role_policy_attachment.policy_arn
    vpce_role_arn                                     = aws_iam_role.vpce_role.arn
    vpce_policy_arn                                   = aws_iam_role_policy_attachment.vpce_role_policy_attachment.policy_arn
    ingress_private_hosted_zone_id                    = aws_route53_zone_association.ingress_private_hosted_zone_association.zone_id
    hcp_internal_communication_private_hosted_zone_id = aws_route53_zone_association.hcp_internal_communication_hosted_zone_association.zone_id
    resource_share_arn                                = aws_ram_principal_association.shared_vpc_resource_share.resource_share_arn
  }
}


resource "aws_ec2_tag" "tag_private_subnets" {
  provider    = aws.cluster-owner
  count       = length(module.vpc.private_subnets)
  resource_id = module.vpc.private_subnets[count.index]
  key         = "kubernetes.io/role/internal-elb"
  value       = ""
}

############################
# ROSA STS cluster
############################
module "rosa_cluster_hcp" {
  source = "../../modules/rosa-cluster-hcp"
  providers = {
    aws = aws.cluster-owner
  }

  cluster_name               = var.cluster_name
  openshift_version          = var.openshift_version
  version_channel_group      = var.version_channel_group
  machine_cidr               = module.vpc.cidr_block
  aws_subnet_ids             = [for resource_arn in aws_ram_resource_association.shared_vpc_resource_association[*].resource_arn : trimprefix(resource_arn, local.resource_arn_prefix)]
  replicas                   = 2
  private                    = true
  create_admin_user          = true
  admin_credentials_username = "admin"
  admin_credentials_password = random_password.password.result
  ec2_metadata_http_tokens   = "required"
  aws_billing_account_id     = var.aws_billing_account_id

  // STS configuration
  oidc_config_id       = module.oidc_config_and_provider.oidc_config_id
  account_role_prefix  = module.account_iam_resources.account_role_prefix
  operator_role_prefix = module.operator_roles.operator_role_prefix
  shared_vpc = {
    ingress_private_hosted_zone_id                = time_sleep.shared_resources_propagation.triggers["ingress_private_hosted_zone_id"]
    internal_communication_private_hosted_zone_id = time_sleep.shared_resources_propagation.triggers["hcp_internal_communication_private_hosted_zone_id"]
    route53_role_arn                              = time_sleep.shared_resources_propagation.triggers["route53_role_arn"]
    vpce_role_arn                                 = time_sleep.shared_resources_propagation.triggers["vpce_role_arn"]
  }
  base_dns_domain = rhcs_dns_domain.dns_domain.id
  aws_additional_allowed_principals = [
    time_sleep.shared_resources_propagation.triggers["route53_role_arn"],
    time_sleep.shared_resources_propagation.triggers["vpce_role_arn"],
  ]
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
# Bastion instance for connection to the cluster
############################

data "aws_ami" "rhel9" {
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
module "bastion_host" {
  providers = {
    aws = aws.network-owner
  }
  source     = "../../modules/bastion-host"
  prefix     = var.cluster_name
  vpc_id     = module.vpc.vpc_id
  subnet_ids = [module.vpc.public_subnets[0]]
  ami_id         = aws_ami.rhel9.id
  user_data_file = file("../../assets/bastion-host-user-data.yaml")
}


locals {
  network_owner_aws_credentials_provided = length(var.network_owner_aws_access_key_id) > 0 && length(var.network_owner_aws_secret_access_key) > 0
  network_owner_aws_profile_provided     = length(var.network_owner_aws_profile) > 0
  cluster_owner_aws_credentials_provided = length(var.cluster_owner_aws_access_key_id) > 0 && length(var.cluster_owner_aws_secret_access_key) > 0
  cluster_owner_aws_profile_provided     = length(var.cluster_owner_aws_profile) > 0
}

resource "null_resource" "validations" {
  lifecycle {
    precondition {
      condition     = (local.network_owner_aws_credentials_provided == false && local.network_owner_aws_profile_provided == false) == false
      error_message = "AWS credentials for the network-owner account must be provided. This can provided with \"var.network_owner_aws_access_key_id\" and \"var.network_owner_aws_secret_access_key\" or with existing profile \"var.network_owner_aws_profile\""
    }
    precondition {
      condition     = (local.cluster_owner_aws_credentials_provided == false && local.cluster_owner_aws_profile_provided == false) == false
      error_message = "AWS credentials for the cluster-owner account must be provided. This can provided with \"var.cluster_owner_aws_access_key_id\" and \"var.cluster_owner_aws_secret_access_key\" or with existing profile \"var.cluster_owner_aws_profile\""
    }
  }
}

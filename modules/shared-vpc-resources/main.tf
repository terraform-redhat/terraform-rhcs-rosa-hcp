locals {
  account_roles_prefix    = var.account_roles_prefix
  installer_role_name     = substr("${local.account_roles_prefix}-HCP-ROSA-Installer-Role", 0, 64)
  installer_role_arn      = "arn:aws:iam::${var.target_aws_account}:role/${local.installer_role_name}"
  operator_roles_prefix   = var.operator_roles_prefix
  ingress_role_name       = substr("${local.operator_roles_prefix}-openshift-ingress-operator-cloud-credentials", 0, 64)
  ingress_role_arn        = "arn:aws:iam::${var.target_aws_account}:role/${local.ingress_role_name}"
  control_plane_role_name = substr("${local.operator_roles_prefix}-kube-system-control-plane-operator", 0, 64)
  control_plane_role_arn  = "arn:aws:iam::${var.target_aws_account}:role/${local.control_plane_role_name}"
}

### Route53 role
module "route53-role" {
  source                 = "./route53-role"
  name_prefix            = var.name_prefix
  installer_role_arn     = local.installer_role_arn
  ingress_role_arn       = local.ingress_role_arn
  control_plane_role_arn = local.control_plane_role_arn
  permission_boundary    = var.route53_permission_boundary
}

### VPCE role
module "vpce-role" {
  source                 = "./vpce-role"
  name_prefix            = var.name_prefix
  installer_role_arn     = local.installer_role_arn
  control_plane_role_arn = local.control_plane_role_arn
  permission_boundary    = var.vpce_permission_boundary
}

### Subnets share
module "subnets-share" {
  source             = "./subnets-share"
  name_prefix        = var.name_prefix
  subnets            = var.subnets
  target_aws_account = var.target_aws_account
}

### Hosted zones
module "hosted-zones" {
  source                                  = "./hosted-zones"
  cluster_name                            = var.cluster_name
  ingress_private_hosted_zone_base_domain = var.ingress_private_hosted_zone_base_domain
  vpc_id                                  = var.vpc_id
}

# This resource is utilized to establish dependencies on all resources.
# Some resources, such as aws_ram_principle_associasion, may not have their output utilized, but they are crucial for the cluster.
# Hence, the creation of these resources must be finalized prior to the initiation of cluster creation, and they should not be removed before the cluster is destroyed.
resource "time_sleep" "shared_resources_propagation" {
  destroy_duration = "20s"
  create_duration  = "20s"

  triggers = {
    route53_role_name                                  = module.route53-role.role_name
    route53_role_arn                                   = module.route53-role.role_arn
    route53_policy_arn                                 = module.route53-role.policy_arn
    vpce_role_name                                     = module.vpce-role.role_name
    vpce_role_arn                                      = module.vpce-role.role_arn
    vpce_policy_arn                                    = module.vpce-role.policy_arn
    ingress_private_hosted_zone_id                     = module.hosted-zones.ingress_private_hosted_zone_id
    hcp_internal_communication_private_hosted_zone_id  = module.hosted-zones.hcp_internal_communication_private_hosted_zone_id
    ingress_private_hosted_zone_arn                    = module.hosted-zones.ingress_private_hosted_zone_arn
    hcp_internal_communication_private_hosted_zone_arn = module.hosted-zones.hcp_internal_communication_private_hosted_zone_arn
    resource_share_arn                                 = module.subnets-share.resource_share_arn
  }
}

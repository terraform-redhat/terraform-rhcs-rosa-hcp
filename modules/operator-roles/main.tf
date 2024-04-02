locals {
  operator_roles_properties = [
    {
      operator_name      = "installer-cloud-credentials"
      operator_namespace = "openshift-image-registry"
      role_name          = "openshift-image-registry-installer-cloud-credentials"
      policy_details     = "arn:aws:iam::aws:policy/service-role/ROSAImageRegistryOperatorPolicy"
      service_accounts   = ["system:serviceaccount:openshift-image-registry:cluster-image-registry-operator", "system:serviceaccount:openshift-image-registry:registry"]
    },
    {
      operator_name      = "cloud-credentials"
      operator_namespace = "openshift-ingress-operator"
      role_name          = "openshift-ingress-operator-cloud-credentials"
      policy_details     = "arn:aws:iam::aws:policy/service-role/ROSAIngressOperatorPolicy"
      service_accounts   = ["system:serviceaccount:openshift-ingress-operator:ingress-operator"]
    },
    {
      operator_name      = "ebs-cloud-credentials"
      operator_namespace = "openshift-cluster-csi-drivers"
      role_name          = "openshift-cluster-csi-drivers-ebs-cloud-credentials"
      policy_details     = "arn:aws:iam::aws:policy/service-role/ROSAAmazonEBSCSIDriverOperatorPolicy"
      service_accounts   = ["system:serviceaccount:openshift-cluster-csi-drivers:aws-ebs-csi-driver-operator", "system:serviceaccount:openshift-cluster-csi-drivers:aws-ebs-csi-driver-controller-sa"]
    },
    {
      operator_name      = "cloud-credentials"
      operator_namespace = "openshift-cloud-network-config-controller"
      role_name          = "openshift-cloud-network-config-controller-cloud-credentials"
      policy_details     = "arn:aws:iam::aws:policy/service-role/ROSACloudNetworkConfigOperatorPolicy"
      service_accounts   = ["system:serviceaccount:openshift-cloud-network-config-controller:cloud-network-config-controller"]
    },
    {
      operator_name      = "kube-controller-manager"
      operator_namespace = "kube-system"
      role_name          = "kube-system-kube-controller-manager"
      policy_details     = "arn:aws:iam::aws:policy/service-role/ROSAKubeControllerPolicy"
      service_accounts   = ["system:serviceaccount:kube-system:kube-controller-manager"]
    },
    {
      operator_name      = "capa-controller-manager"
      operator_namespace = "kube-system"
      role_name          = "kube-system-capa-controller-manager"
      policy_details     = "arn:aws:iam::aws:policy/service-role/ROSANodePoolManagementPolicy"
      service_accounts   = ["system:serviceaccount:kube-system:capa-controller-manager"]
    },
    {
      operator_name      = "control-plane-operator"
      operator_namespace = "kube-system"
      role_name          = "kube-system-control-plane-operator"
      policy_details     = "arn:aws:iam::aws:policy/service-role/ROSAControlPlaneOperatorPolicy"
      service_accounts   = ["system:serviceaccount:kube-system:control-plane-operator"]
    },
    {
      operator_name      = "kms-provider"
      operator_namespace = "kube-system"
      role_name          = "kube-system-kms-provider"
      policy_details     = "arn:aws:iam::aws:policy/service-role/ROSAKMSProviderPolicy"
      service_accounts   = ["system:serviceaccount:kube-system:kms-provider"]
    },
  ]
  operator_roles_count = length(local.operator_roles_properties)
  operator_role_prefix = var.operator_role_prefix
  path                 = coalesce(var.path, "/")
}

data "aws_iam_policy_document" "custom_trust_policy" {
  count = local.operator_roles_count

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_endpoint_url}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_endpoint_url}:sub"
      values   = local.operator_roles_properties[count.index].service_accounts
    }
  }
}

module "operator_iam_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = ">=5.34.0"
  count  = local.operator_roles_count

  create_role = true

  role_name = substr("${local.operator_role_prefix}-${local.operator_roles_properties[count.index].operator_namespace}-${local.operator_roles_properties[count.index].operator_name}", 0, 64)

  role_path                     = local.path
  role_permissions_boundary_arn = var.permissions_boundary

  create_custom_role_trust_policy = true
  custom_role_trust_policy        = data.aws_iam_policy_document.custom_trust_policy[count.index].json

  custom_role_policy_arns = [
    local.operator_roles_properties[count.index].policy_details
  ]

  tags = merge(var.tags, {
    rosa_managed_policies  = true
    rosa_hcp_policies      = true
    red-hat-managed        = true
    operator_namespace = local.operator_roles_properties[count.index].operator_namespace
    operator_name      = local.operator_roles_properties[count.index].operator_name
  })
}

data "aws_caller_identity" "current" {}

resource "time_sleep" "role_resources_propagation" {
  create_duration = "20s"
  triggers = {
    operator_role_prefix = local.operator_role_prefix
    operator_role_arns   = jsonencode([for value in module.operator_iam_role : value.iam_role_arn])
  }
}

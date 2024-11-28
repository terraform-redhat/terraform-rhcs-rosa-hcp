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

  route53_shared_role_arn = var.shared_vpc_roles["route53"]
  route53_splits          = split("/", local.route53_shared_role_arn)
  route53_role_name       = local.route53_splits[length(local.route53_splits) - 1]
  route53_policy_name     = substr("${local.route53_role_name}-route53-assume-role", 0, 64)
  vpce_shared_role_arn    = var.shared_vpc_roles["vpce"]
  vpce_splits             = split("/", local.vpce_shared_role_arn)
  vpce_role_name          = local.vpce_splits[length(local.vpce_splits) - 1]
  vpce_policy_name        = substr("${local.vpce_role_name}-vpce-assume-role", 0, 64)

  policy_arn_base = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy"
}

data "aws_caller_identity" "current" {}

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

resource "aws_iam_role" "operator_role" {
  count                = local.operator_roles_count
  name                 = substr("${local.operator_role_prefix}-${local.operator_roles_properties[count.index].operator_namespace}-${local.operator_roles_properties[count.index].operator_name}", 0, 64)
  permissions_boundary = var.permissions_boundary
  path                 = local.path
  assume_role_policy   = data.aws_iam_policy_document.custom_trust_policy[count.index].json

  tags = merge(var.tags, {
    rosa_managed_policies = true
    rosa_hcp_policies     = true
    red-hat-managed       = true
    operator_namespace    = local.operator_roles_properties[count.index].operator_namespace
    operator_name         = local.operator_roles_properties[count.index].operator_name
  })
}

resource "aws_iam_role_policy_attachment" "operator_role_policy_attachment" {
  count      = local.operator_roles_count
  role       = aws_iam_role.operator_role[count.index].name
  policy_arn = local.operator_roles_properties[count.index].policy_details
}

### Shared VPC resources
resource "aws_iam_policy" "route53_policy" {
  count = (local.route53_shared_role_arn != "" && var.create_shared_vpc_policies) ? 1 : 0

  name = substr("${local.route53_role_name}-route53-assume-role", 0, 64)
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AssumeInto",
        "Effect" : "Allow",
        "Action" : "sts:AssumeRole",
        "Resource" : "${local.route53_shared_role_arn}"
      }
    ]
  })
  path = local.path
}

resource "aws_iam_policy" "vpce_policy" {
  count = (local.vpce_shared_role_arn != "" && var.create_shared_vpc_policies) ? 1 : 0

  name = substr("${local.vpce_role_name}-vpce-assume-role", 0, 64)
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AssumeInto",
        "Effect" : "Allow",
        "Action" : "sts:AssumeRole",
        "Resource" : "${local.vpce_shared_role_arn}"
      }
    ]
  })
  path = local.path
}

resource "aws_iam_role_policy_attachment" "route53_policy_ingress_operator_role_attachment" {
  count      = local.route53_shared_role_arn != "" ? 1 : 0
  role       = substr("${local.operator_role_prefix}-${local.operator_roles_properties[1].role_name}", 0, 64)
  policy_arn = var.create_shared_vpc_policies ? aws_iam_policy.route53_policy[0].arn : "${local.policy_arn_base}${local.path}${local.route53_policy_name}"
  depends_on = [aws_iam_role_policy_attachment.operator_role_policy_attachment]
}

resource "aws_iam_role_policy_attachment" "route53_policy_control_plane_operator_role_attachment" {
  count      = local.route53_shared_role_arn != "" ? 1 : 0
  role       = substr("${local.operator_role_prefix}-${local.operator_roles_properties[6].role_name}", 0, 64)
  policy_arn = var.create_shared_vpc_policies ? aws_iam_policy.route53_policy[0].arn : "${local.policy_arn_base}${local.path}${local.route53_policy_name}"
  depends_on = [aws_iam_role_policy_attachment.operator_role_policy_attachment]
}

resource "aws_iam_role_policy_attachment" "vpce_policy_control_plane_operator_role_attachment" {
  count      = local.vpce_shared_role_arn != "" ? 1 : 0
  role       = substr("${local.operator_role_prefix}-${local.operator_roles_properties[6].role_name}", 0, 64)
  policy_arn = var.create_shared_vpc_policies ? aws_iam_policy.vpce_policy[0].arn : "${local.policy_arn_base}${local.path}${local.vpce_policy_name}"
  depends_on = [aws_iam_role_policy_attachment.operator_role_policy_attachment]
}

#### Outputs
resource "time_sleep" "role_resources_propagation" {
  create_duration = "20s"
  triggers = {
    operator_role_prefix = local.operator_role_prefix
    operator_role_arns   = jsonencode([for value in aws_iam_role.operator_role : value.arn])
    operator_policy_arns = jsonencode([for value in aws_iam_role_policy_attachment.operator_role_policy_attachment : value.policy_arn])
  }
}

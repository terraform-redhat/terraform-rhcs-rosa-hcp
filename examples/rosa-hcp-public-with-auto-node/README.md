# ROSA HCP Public with AutoNode

## Introduction

This is a Terraform manifest example for creating a Red Hat OpenShift Service on AWS (ROSA) Hosted Control Plane (HCP) cluster. This example provides a structured configuration template that demonstrates how to deploy a ROSA cluster within your AWS environment by using Terraform.

This example includes:
- A ROSA cluster with public access.
- AutoNode (Karpenter) enabled. The Karpenter IAM role is created by this example and passed through `auto_node.role_arn`. AutoNode requires OpenShift 4.22 or later and can't be disabled after it's enabled.
- All AWS resources (IAM and networking) that are created as part of the ROSA cluster module execution.

## Example Usage

This example uses `source = "../../"`, so run it from a checkout that includes the `auto_node` input. After a release declares it, switch to the registry source and pin that release.

```
locals {
  account_role_prefix  = "${var.cluster_name}-account"
  operator_role_prefix = "${var.cluster_name}-operator"
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

############################
# Karpenter (AutoNode) IAM role
############################
data "aws_iam_policy_document" "karpenter_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${module.hcp.oidc_endpoint_url}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${module.hcp.oidc_endpoint_url}:sub"
      values   = ["system:serviceaccount:kube-system:karpenter"]
    }
  }
}

resource "aws_iam_role" "karpenter" {
  name               = "${local.operator_role_prefix}-kube-system-karpenter"
  assume_role_policy = data.aws_iam_policy_document.karpenter_trust.json

  tags = {
    red-hat-managed = "true"
  }
}

resource "aws_iam_role_policy_attachment" "karpenter" {
  role       = aws_iam_role.karpenter.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/ROSAKarpenterControllerPolicy"
}

# Read the role back after the policy is attached so cluster creation (and AutoNode
# activation) waits for the attachment. A depends_on on module.hcp would create a
# cycle through the trust policy's module.hcp.oidc_endpoint_url reference.
data "aws_iam_role" "karpenter" {
  name       = aws_iam_role.karpenter.name
  depends_on = [aws_iam_role_policy_attachment.karpenter]
}

############################
# Cluster
############################
module "hcp" {
  source = "../../"

  cluster_name             = var.cluster_name
  openshift_version        = var.openshift_version
  machine_cidr             = module.vpc.cidr_block
  aws_subnet_ids           = concat(module.vpc.public_subnets, module.vpc.private_subnets)
  aws_availability_zones   = module.vpc.availability_zones
  replicas                 = length(module.vpc.availability_zones)
  create_admin_user        = true
  ec2_metadata_http_tokens = "required"

  // STS configuration
  create_account_roles  = true
  account_role_prefix   = local.account_role_prefix
  create_oidc           = true
  create_operator_roles = true
  operator_role_prefix  = local.operator_role_prefix

  // AutoNode (Karpenter). The Karpenter IAM role is created above in this example.
  // Requires OpenShift 4.22 or later.
  auto_node = {
    mode     = "enabled"
    role_arn = data.aws_iam_role.karpenter.arn
  }
}

############################
# HTPASSWD IDP
############################
module "htpasswd_idp" {
  source = "../../modules/idp"

  cluster_id         = module.hcp.cluster_id
  name               = "htpasswd-idp"
  idp_type           = "htpasswd"
  htpasswd_idp_users = [{ username = "test-user", password = random_password.password.result }]
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
# VPC
############################
module "vpc" {
  source = "../../modules/vpc"

  name_prefix                       = var.cluster_name
  availability_zones_count          = 3
  cleanup_rosa_vpce_security_groups = true
}
```

<!-- BEGIN_AUTOMATED_TF_DOCS_BLOCK -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | = 6.54.0 |
| <a name="requirement_rhcs"></a> [rhcs](#requirement\_rhcs) | = 1.7.10 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | = 6.54.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_hcp"></a> [hcp](#module\_hcp) | ../../ | n/a |
| <a name="module_htpasswd_idp"></a> [htpasswd\_idp](#module\_htpasswd\_idp) | ../../modules/idp | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../modules/vpc | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_role.karpenter](https://registry.terraform.io/providers/hashicorp/aws/6.54.0/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.karpenter](https://registry.terraform.io/providers/hashicorp/aws/6.54.0/docs/resources/iam_role_policy_attachment) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/6.54.0/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.karpenter_trust](https://registry.terraform.io/providers/hashicorp/aws/6.54.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_role.karpenter](https://registry.terraform.io/providers/hashicorp/aws/6.54.0/docs/data-sources/iam_role) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/6.54.0/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the cluster. After the creation of the resource, it is not possible to update the attribute value. | `string` | n/a | yes |
| <a name="input_openshift_version"></a> [openshift\_version](#input\_openshift\_version) | The required version of Red Hat OpenShift for the cluster, for example '4.1.0'. If version is greater than the currently running version, an upgrade will be scheduled. | `string` | `"4.22.0"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_account_role_prefix"></a> [account\_role\_prefix](#output\_account\_role\_prefix) | The prefix used for all generated AWS resources. |
| <a name="output_account_roles_arn"></a> [account\_roles\_arn](#output\_account\_roles\_arn) | A map of Amazon Resource Names (ARNs) associated with the AWS IAM roles created. The key in the map represents the name of an AWS IAM role, while the corresponding value represents the associated Amazon Resource Name (ARN) of that role. |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | Unique identifier of the cluster. |
| <a name="output_karpenter_role_arn"></a> [karpenter\_role\_arn](#output\_karpenter\_role\_arn) | ARN of the IAM role used by the Karpenter controller (AutoNode). |
| <a name="output_oidc_config_id"></a> [oidc\_config\_id](#output\_oidc\_config\_id) | The unique identifier associated with users authenticated through OpenID Connect (OIDC) generated by this OIDC config. |
| <a name="output_oidc_endpoint_url"></a> [oidc\_endpoint\_url](#output\_oidc\_endpoint\_url) | Registered OIDC configuration issuer URL, generated by this OIDC config. |
| <a name="output_operator_role_prefix"></a> [operator\_role\_prefix](#output\_operator\_role\_prefix) | Prefix used for generated AWS operator policies. |
| <a name="output_operator_roles_arn"></a> [operator\_roles\_arn](#output\_operator\_roles\_arn) | List of Amazon Resource Names (ARNs) for all operator roles created. |
| <a name="output_password"></a> [password](#output\_password) | n/a |
| <a name="output_path"></a> [path](#output\_path) | The arn path for the account/operator roles as well as their policies. |
<!-- END_AUTOMATED_TF_DOCS_BLOCK -->

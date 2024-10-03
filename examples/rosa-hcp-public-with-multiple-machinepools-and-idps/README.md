# ROSA Hosted Control Plane public with multiple IDPs and machine pools

## Introduction

This is a Terraform manifest example for creating a Red Hat OpenShift Service on AWS (ROSA) cluster. This example provides a structured configuration template that demonstrates how to deploy a ROSA cluster within your AWS environment using Terraform.

This example includes:
- A ROSA Cluster with public access and managed OIDC.
- All AWS resources (IAM and networking) that are created as part of the ROSA cluster module execution
- "Day 2" Machine pool resources - created as part of the root module execution - map of multiple resources is provided.
- "Day 2" Identity provider resource - created as part of the root module execution - map of multiple resources is provided.

Note: This example involves the creation of various identity providers using placeholder values for illustrative purposes. These providers will not grant access to the cluster with the exception of the HTPasswd identity provider. You must supply your own pre-configured values for authentic identity providers.

## Prerequisites

* You have installed the [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) (1.4.6+).
* You have an [AWS account](https://aws.amazon.com/free/?all-free-tier) and [associated credentials](https://docs.aws.amazon.com/IAM/latest/UserGuide/security-creds.html) that you can use to create resources. The credentials configured for the AWS provider (see the [Authentication and Configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration) section in the AWS Terraform provider documentation).
* You have completed the [ROSA getting started AWS prerequisites](https://console.redhat.com/openshift/create/rosa/getstarted).
* You have a valid [OpenShift Cluster Manager API Token](https://console.redhat.com/openshift/token) configured (see [Authentication and configuration](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs#authentication-and-configuration) for more info).
* Recommended: You have installed the following CLI tools:
    * [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
    * [ROSA CLI](https://docs.openshift.com/rosa/cli_reference/rosa_cli/rosa-get-started-cli.html)
    * [Openshift CLI (oc)](https://docs.openshift.com/rosa/cli_reference/openshift_cli/getting-started-cli.html)

## Example usage

```
locals {
  account_role_prefix  = "my-cluster-account"
  operator_role_prefix = "my-cluster-operator"
}

module "hcp" {
  source = "../../"

  cluster_name           = "my-cluster"
  openshift_version      = "4.16.13"
  machine_cidr           = module.vpc.cidr_block
  aws_subnet_ids         = concat(module.vpc.public_subnets, module.vpc.private_subnets)
  aws_availability_zones = module.vpc.availability_zones
  replicas               = length(module.vpc.availability_zones)

  // STS configuration
  create_account_roles  = true
  account_role_prefix   = local.account_role_prefix
  create_oidc           = true
  create_operator_roles = true
  operator_role_prefix  = local.operator_role_prefix
  kubelet_configs = {
    config1 = {
      name = "config1"
      pod_pids_limit = 8192
    },
    config2 = {
      name = "config2"
      pod_pids_limit = 16384
    }
  }
  machine_pools = {
    pool1 = {
      name = "pool1"
      aws_node_pool = {
        instance_type = "r5.xlarge"
        tags = {}
      }
      auto_repair = true
      replicas = 3
      openshift_version = "4.16.13"
      subnet_id = module.vpc.private_subnets[0]
      kubelet_configs = "config1"
    },
    pool2 = {
      name = "pool2"
      aws_node_pool = {
        instance_type = "r5.xlarge"
        tags = {}
      }
      auto_repair = true
      replicas = 3
      openshift_version = "4.16.13"
      subnet_id = module.vpc.private_subnets[1]
      kubelet_configs = "config2"
    },
  }
  identity_providers = {
    gitlab-idp = {
      name                     = "gitlab-idp"
      idp_type                 = "gitlab"
      gitlab_idp_client_id     = random_password.client_id.result     # replace with valid <client-id>
      gitlab_idp_client_secret = random_password.client_secret.result # replace with valid <client-secret>
      gitlab_idp_url           = "https://gitlab.com"
    },
    htpasswd-idp = {
      name               = "htpasswd-idp"
      idp_type           = "htpasswd"
      htpasswd_idp_users = jsonencode([{ username = "test-user", password = random_password.password.result }])
    },
    github-idp = {
      name                     = "github-idp"
      idp_type                 = "github"
      github_idp_client_id     = random_password.client_id.result     # replace with valid <client-id>
      github_idp_client_secret = random_password.client_secret.result # replace with valid <client-secret>
      github_idp_organizations = jsonencode(["example"])
    },
    google-idp = {
      name                     = "google-idp"
      idp_type                 = "google"
      google_idp_client_id     = random_password.client_id.result     # replace with valid <client-id>
      google_idp_client_secret = random_password.client_secret.result # replace with valid <client-secret>
      google_idp_hosted_domain = "example.com"
    },
    ldap-idp = {
      name              = "ldap-idp"
      idp_type          = "ldap"
      ldap_idp_ca       = ""
      ldap_idp_url      = "ldap://ldap.forumsys.com/dc=example,dc=com?uid"
      ldap_idp_insecure = true
    },
    openid-idp = {
      name                                 = "openid-idp"
      idp_type                             = "openid"
      openid_idp_client_id                 = random_password.client_id.result     # replace with valid <client-id>
      openid_idp_client_secret             = random_password.client_secret.result # replace with valid <client-secret>
      openid_idp_ca                        = ""
      openid_idp_issuer                    = "https://example.com"
      openid_idp_claims_email              = jsonencode(["example@email.com"])
      openid_idp_claims_groups             = jsonencode(["example"])
      openid_idp_claims_name               = jsonencode(["example"])
      openid_idp_claims_preferred_username = jsonencode(["example"])
    },
  }
}

resource "random_password" "client_id" {
  length = 16

  numeric     = true
  upper       = false
  lower       = false
  special     = false
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

resource "random_password" "client_secret" {
  length = 39

  numeric     = true
  upper       = true
  lower       = false
  special     = false
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
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

  name_prefix              = "my-cluster-vpc"
  availability_zones_count = 3
}


```

<!-- BEGIN_AUTOMATED_TF_DOCS_BLOCK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 2.0 |
| <a name="requirement_rhcs"></a> [rhcs](#requirement\_rhcs) | >= 1.6.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | >= 2.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_hcp"></a> [hcp](#module\_hcp) | ../../ | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../modules/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [random_password.client_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.client_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the cluster. After the creation of the resource, it is not possible to update the attribute value. | `string` | n/a | yes |
| <a name="input_openshift_version"></a> [openshift\_version](#input\_openshift\_version) | The required version of Red Hat OpenShift for the cluster, for example '4.1.0'. If version is greater than the currently running version, an upgrade will be scheduled. | `string` | `"4.14.9"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_role_prefix"></a> [account\_role\_prefix](#output\_account\_role\_prefix) | The prefix used for all generated AWS resources. |
| <a name="output_account_roles_arn"></a> [account\_roles\_arn](#output\_account\_roles\_arn) | A map of Amazon Resource Names (ARNs) associated with the AWS IAM roles created. The key in the map represents the name of an AWS IAM role, while the corresponding value represents the associated Amazon Resource Name (ARN) of that role. |
| <a name="output_client_id"></a> [client\_id](#output\_client\_id) | n/a |
| <a name="output_client_secret"></a> [client\_secret](#output\_client\_secret) | n/a |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | Unique identifier of the cluster. |
| <a name="output_oidc_config_id"></a> [oidc\_config\_id](#output\_oidc\_config\_id) | The unique identifier associated with users authenticated through OpenID Connect (OIDC) generated by this OIDC config. |
| <a name="output_oidc_endpoint_url"></a> [oidc\_endpoint\_url](#output\_oidc\_endpoint\_url) | Registered OIDC configuration issuer URL, generated by this OIDC config. |
| <a name="output_operator_role_prefix"></a> [operator\_role\_prefix](#output\_operator\_role\_prefix) | Prefix used for generated AWS operator policies. |
| <a name="output_operator_roles_arn"></a> [operator\_roles\_arn](#output\_operator\_roles\_arn) | List of Amazon Resource Names (ARNs) for all operator roles created. |
| <a name="output_password"></a> [password](#output\_password) | n/a |
| <a name="output_path"></a> [path](#output\_path) | The arn path for the account/operator roles as well as their policies. |
<!-- END_AUTOMATED_TF_DOCS_BLOCK -->

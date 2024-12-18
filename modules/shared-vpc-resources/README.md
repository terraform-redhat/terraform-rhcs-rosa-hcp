# shared-vpc-resources

## Introduction

This sub-module enables the creation of all essential AWS resources within the shared VPC account to support the shared VPC infrastructure. It encompasses the provisioning of IAM resources to facilitate sharing between accounts, ensuring seamless collaboration and resource access. Additionally, the module handles the configuration of two Route 53 hosted zones, enabling external access into the VPC for enhanced connectivity and service accessibility.

The operator roles and installer account role must exist so that it is possible to create the trust policy.

<!-- BEGIN_AUTOMATED_TF_DOCS_BLOCK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_time"></a> [time](#provider\_time) | >= 0.9 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_hosted-zones"></a> [hosted-zones](#module\_hosted-zones) | ./hosted-zones | n/a |
| <a name="module_route53-role"></a> [route53-role](#module\_route53-role) | ./route53-role | n/a |
| <a name="module_subnets-share"></a> [subnets-share](#module\_subnets-share) | ./subnets-share | n/a |
| <a name="module_vpce-role"></a> [vpce-role](#module\_vpce-role) | ./vpce-role | n/a |

## Resources

| Name | Type |
|------|------|
| [time_sleep.shared_resources_propagation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_roles_prefix"></a> [account\_roles\_prefix](#input\_account\_roles\_prefix) | Prefix used to compute installer account role | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The cluster's name for which shared resources are created. It is used for the hosted zone domain. | `string` | n/a | yes |
| <a name="input_ingress_private_hosted_zone_base_domain"></a> [ingress\_private\_hosted\_zone\_base\_domain](#input\_ingress\_private\_hosted\_zone\_base\_domain) | The base domain that must be used for hosted zone creation. | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | The prefix applied to all AWS creations. | `string` | n/a | yes |
| <a name="input_operator_roles_prefix"></a> [operator\_roles\_prefix](#input\_operator\_roles\_prefix) | Prefix used to compute ingress and control plane operator roles | `string` | n/a | yes |
| <a name="input_route53_permission_boundary"></a> [route53\_permission\_boundary](#input\_route53\_permission\_boundary) | Route53 role permission boundary arn | `string` | `null` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | The list of the subnets that must be shared between the accounts. | `list(string)` | n/a | yes |
| <a name="input_target_aws_account"></a> [target\_aws\_account](#input\_target\_aws\_account) | The AWS account number where the cluster is created. | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The Shared VPC ID. | `string` | n/a | yes |
| <a name="input_vpce_permission_boundary"></a> [vpce\_permission\_boundary](#input\_vpce\_permission\_boundary) | VPCE role permission boundary arn | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_hcp_internal_communication_private_hosted_zone_arn"></a> [hcp\_internal\_communication\_private\_hosted\_zone\_arn](#output\_hcp\_internal\_communication\_private\_hosted\_zone\_arn) | HCP Internal Communication Private Hosted Zone ARN |
| <a name="output_hcp_internal_communication_private_hosted_zone_id"></a> [hcp\_internal\_communication\_private\_hosted\_zone\_id](#output\_hcp\_internal\_communication\_private\_hosted\_zone\_id) | HCP Internal Communication Private Hosted Zone ID |
| <a name="output_ingress_private_hosted_zone_arn"></a> [ingress\_private\_hosted\_zone\_arn](#output\_ingress\_private\_hosted\_zone\_arn) | Ingress Private Hosted Zone ARN |
| <a name="output_ingress_private_hosted_zone_id"></a> [ingress\_private\_hosted\_zone\_id](#output\_ingress\_private\_hosted\_zone\_id) | Ingress Private Hosted Zone ID |
| <a name="output_route53_role_arn"></a> [route53\_role\_arn](#output\_route53\_role\_arn) | Route53 Role ARN |
| <a name="output_route53_role_name"></a> [route53\_role\_name](#output\_route53\_role\_name) | Route53 Role name |
| <a name="output_shared_subnets"></a> [shared\_subnets](#output\_shared\_subnets) | The Amazon Resource Names (ARN) of the resource share |
| <a name="output_vpce_role_arn"></a> [vpce\_role\_arn](#output\_vpce\_role\_arn) | VPCE Role ARN |
| <a name="output_vpce_role_name"></a> [vpce\_role\_name](#output\_vpce\_role\_name) | VPCE Role name |
<!-- END_AUTOMATED_TF_DOCS_BLOCK -->
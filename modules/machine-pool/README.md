# machine-pool

## Introduction

This Terraform sub-module manages the machine pool for ROSA HCP clusters. It enables you to efficiently configure and scale machine pools after cluster deployment, ensuring optimal resource allocation and performance for workloads within the ROSA HCP cluster environment. With this module, you can easily adjust the size and specifications of machine pools, facilitating seamless adaptation to changing workload demands and operational requirements in ROSA HCP clusters.

<!-- BEGIN_AUTOMATED_TF_DOCS_BLOCK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_rhcs"></a> [rhcs](#requirement\_rhcs) | >= 1.6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_rhcs"></a> [rhcs](#provider\_rhcs) | >= 1.6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [rhcs_hcp_machine_pool.machine_pool](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/hcp_machine_pool) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_autoscaling"></a> [autoscaling](#input\_autoscaling) | Configures autoscaling for the pool. | <pre>object({<br>    enabled = bool<br>    min_replicas = number<br>    max_replicas = number<br>  })</pre> | <pre>{<br>  "enabled": false,<br>  "max_replicas": null,<br>  "min_replicas": null<br>}</pre> | no |
| <a name="input_aws_node_pool"></a> [aws\_node\_pool](#input\_aws\_node\_pool) | Configures aws settings for the pool. | <pre>object({<br>    instance_type = string<br>    tags = map(string)<br>  })</pre> | `null` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | Identifier of the cluster. | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels for the machine pool. Format should be a comma-separated list of 'key = value'. This list will overwrite any modifications made to node labels on an ongoing basis. | `map(string)` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the machine pool. Must consist of lower-case alphanumeric characters or '-', start and end with an alphanumeric character. | `string` | n/a | yes |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | The amount of the machine created in this machine pool. | `number` | `null` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Select the subnet in which to create a single AZ machine pool for BYO-VPC cluster | `string` | `null` | no |
| <a name="input_taints"></a> [taints](#input\_taints) | Taints for a machine pool. This list will overwrite any modifications made to node taints on an ongoing basis. | <pre>list(object({<br>    key           = string<br>    value         = string<br>    schedule_type = string<br>  }))</pre> | `null` | no |

## Outputs

No outputs.
<!-- END_AUTOMATED_TF_DOCS_BLOCK -->
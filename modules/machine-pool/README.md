# machine-pool

## Introduction

This Terraform sub-module manages the machine pool for ROSA HCP clusters. It enables you to efficiently configure and scale machine pools after cluster deployment, ensuring optimal resource allocation and performance for workloads within the ROSA HCP cluster environment. With this module, you can easily adjust the size and specifications of machine pools, facilitating seamless adaptation to changing workload demands and operational requirements in ROSA HCP clusters.

## Example Usage

```
module "mp" {
  source = "terraform-redhat/rosa-hcp/rhcs//modules/machine-pool"
  version = "1.6.2"

  cluster_id = "cluster-id-123"
  name = "my-pool"
  openshift_version = "my-version"

  aws_node_pool = {
    instance_type = "my-instance"
    tags = {}
    additional_security_group_ids = [""]
  }

  subnet_id = "subnet-123"
  autoscaling = {
    enabled = false
    min_replicas = null
    max_replicas = null
  }
  replicas = 2
}
```

<!-- BEGIN_AUTOMATED_TF_DOCS_BLOCK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_rhcs"></a> [rhcs](#requirement\_rhcs) | >= 1.6.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_rhcs"></a> [rhcs](#provider\_rhcs) | >= 1.6.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [rhcs_hcp_machine_pool.machine_pool](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/hcp_machine_pool) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_auto_repair"></a> [auto\_repair](#input\_auto\_repair) | Configures auto repair option for the pool. | `bool` | `true` | no |
| <a name="input_autoscaling"></a> [autoscaling](#input\_autoscaling) | Configures autoscaling for the pool. | <pre>object({<br>    enabled      = bool<br>    min_replicas = number<br>    max_replicas = number<br>  })</pre> | <pre>{<br>  "enabled": false,<br>  "max_replicas": null,<br>  "min_replicas": null<br>}</pre> | no |
| <a name="input_aws_node_pool"></a> [aws\_node\_pool](#input\_aws\_node\_pool) | Configures aws settings for the pool. | <pre>object({<br>    instance_type = string<br>    tags = map(string)<br>    additional_security_group_ids = list(string)<br>  })</pre> | n/a | yes |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | Identifier of the cluster. | `string` | n/a | yes |
| <a name="input_ignore_deletion_error"></a> [ignore\_deletion\_error](#input\_ignore\_deletion\_error) | Ignore machine pool deletion error. Assists when cluster resource is managed within the same file for the destroy use case | `bool` | `false` | no |
| <a name="input_kubelet_configs"></a> [kubelet\_configs](#input\_kubelet\_configs) | Name of the kubelet configs to attach to this machine pool. The kubelet configs must already exist | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels for the machine pool. Format should be a comma-separated list of 'key = value'. This list will overwrite any modifications made to node labels on an ongoing basis. | `map(string)` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the machine pool. Must consist of lower-case alphanumeric characters or '-', start and end with an alphanumeric character. | `string` | n/a | yes |
| <a name="input_openshift_version"></a> [openshift\_version](#input\_openshift\_version) | Desired version of OpenShift for the cluster, for example '4.1.0'. If version is greater than the currently running version, an upgrade will be scheduled. | `string` | n/a | yes |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | The amount of the machine created in this machine pool. | `number` | `null` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Select the subnet in which to create a single AZ machine pool for BYO-VPC cluster | `string` | n/a | yes |
| <a name="input_taints"></a> [taints](#input\_taints) | Taints for a machine pool. This list will overwrite any modifications made to node taints on an ongoing basis. | <pre>list(object({<br>    key           = string<br>    value         = string<br>    schedule_type = string<br>  }))</pre> | `null` | no |
| <a name="input_tuning_configs"></a> [tuning\_configs](#input\_tuning\_configs) | A list of tuning config names to attach to this machine pool. The tuning configs must already exist | `list(string)` | `null` | no |
| <a name="input_upgrade_acknowledgements_for"></a> [upgrade\_acknowledgements\_for](#input\_upgrade\_acknowledgements\_for) | Indicates acknowledgement of agreements required to upgrade the cluster version between minor versions (e.g. a value of "4.12" indicates acknowledgement of any agreements required to upgrade to OpenShift 4.12.z from 4.11 or before). | `string` | `null` | no |

## Outputs

No outputs.
<!-- END_AUTOMATED_TF_DOCS_BLOCK -->
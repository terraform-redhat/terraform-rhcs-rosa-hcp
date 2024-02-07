## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_rhcs"></a> [rhcs](#requirement\_rhcs) | >= 1.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_rhcs"></a> [rhcs](#provider\_rhcs) | >= 1.4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [rhcs_machine_pool.machine_pool](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/machine_pool) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_autoscaling_enabled"></a> [autoscaling\_enabled](#input\_autoscaling\_enabled) | Enables autoscaling. If `true`, this variable requires you to set a maximum and minimum replicas range using the `max_replicas` and `min_replicas` variables. | `bool` | `null` | no |
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | Select the availability zone in which to create a single AZ machine pool for a multi-AZ cluster | `string` | `null` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | Identifier of the cluster. | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels for the machine pool. Format should be a comma-separated list of 'key = value'. This list will overwrite any modifications made to node labels on an ongoing basis. | `map(string)` | `null` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | Identifier of the machine type used by the nodes, for example `m5.xlarge`. Use the `rhcs_machine_types` data source to find the possible values. | `string` | n/a | yes |
| <a name="input_max_replicas"></a> [max\_replicas](#input\_max\_replicas) | The maximum number of replicas for autoscaling functionality. | `number` | `null` | no |
| <a name="input_max_spot_price"></a> [max\_spot\_price](#input\_max\_spot\_price) | Max Spot price. | `number` | `null` | no |
| <a name="input_min_replicas"></a> [min\_replicas](#input\_min\_replicas) | The minimum number of replicas for autoscaling functionality. | `number` | `null` | no |
| <a name="input_multi_availability_zone"></a> [multi\_availability\_zone](#input\_multi\_availability\_zone) | Create a multi-AZ machine pool for a multi-AZ cluster (default is `true`) | `bool` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the machine pool. Must consist of lower-case alphanumeric characters or '-', start and end with an alphanumeric character. | `string` | n/a | yes |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | The amount of the machine created in this machine pool. | `number` | `null` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Select the subnet in which to create a single AZ machine pool for BYO-VPC cluster | `string` | `null` | no |
| <a name="input_taints"></a> [taints](#input\_taints) | Taints for a machine pool. This list will overwrite any modifications made to node taints on an ongoing basis. | <pre>list(object({<br>    key           = string<br>    value         = string<br>    schedule_type = string<br>  }))</pre> | `null` | no |
| <a name="input_use_spot_instances"></a> [use\_spot\_instances](#input\_use\_spot\_instances) | Use Amazon EC2 Spot Instances. | `bool` | `null` | no |

## Outputs

No outputs.

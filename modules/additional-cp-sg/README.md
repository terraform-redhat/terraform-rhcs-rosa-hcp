<!-- BEGIN_AUTOMATED_TF_DOCS_BLOCK -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.6 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.6 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_vpc_endpoint_security_group_association.control_plane_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_security_group_association) | resource |
| [aws_subnet.aws_subnet_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_vpc_endpoint.control_plane](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc_endpoint) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_additional_control_plane_security_group_ids"></a> [aws\_additional\_control\_plane\_security\_group\_ids](#input\_aws\_additional\_control\_plane\_security\_group\_ids) | The additional security group IDs to be added to the control plane VPC endpoint. | `list(string)` | `[]` | no |
| <a name="input_aws_subnet_id"></a> [aws\_subnet\_id](#input\_aws\_subnet\_id) | ROSA cluster subnet ID. Used to retrieve VPC ID the subnet belongs to. | `string` | n/a | yes |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | Identifier of the cluster. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_AUTOMATED_TF_DOCS_BLOCK -->
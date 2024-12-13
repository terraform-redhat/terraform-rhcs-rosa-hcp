# vpc

## Introduction

This Terraform sub-module allow you to Bring Your Own VPC (BYO VPC) for ROSA HCP clusters. It enables you to provision and configure all necessary resources within an existing AWS VPC, ensuring compatibility and seamless integration with ROSA deployments. By leveraging this module, you can efficiently set up your own VPC environment, complete with networking components such as subnets, route tables, internet gateways, NAT gateways, and security groups, tailored specifically for ROSA HCP cluster requirements. This flexibility allows for a smooth change if you prefer to use your own VPC infrastructure while leveraging the capabilities of ROSA.

## Example Usage

```
module "vpc" {
  source = "terraform-redhat/rosa-hcp/rhcs//modules/vpc"

  name_prefix              = "my-vpc"
  availability_zones_count = 3
}
```

<!-- BEGIN_AUTOMATED_TF_DOCS_BLOCK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.38.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.38.0 |
| <a name="provider_time"></a> [time](#provider\_time) | >= 0.9 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_zero_egress"></a> [zero\_egress](#module\_zero\_egress) | ./zero-egress | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_eip.eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.public_nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.ipv4_egress_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.ipv6_egress_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.private_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.private_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private_route_table_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public_route_table_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.private_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint_route_table_association.private_vpc_endpoint_route_table_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_route_table_association) | resource |
| [time_sleep.vpc_resources_wait](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | A list of availability zones names in the region.  This value should not be updated, please create a new resource instead | `list(string)` | `null` | no |
| <a name="input_availability_zones_count"></a> [availability\_zones\_count](#input\_availability\_zones\_count) | The count of availability zones to utilize within the specified AWS Region, where pairs of public and private subnets will be generated. Valid only when availability\_zones variable is not provided. This value should not be updated, please create a new resource instead | `number` | `null` | no |
| <a name="input_is_zero_egress"></a> [is\_zero\_egress](#input\_is\_zero\_egress) | Indicates intention for zero egress vpc. | `bool` | `false` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | User-defined prefix for all generated AWS resources of this VPC. This value should not be updated, please create a new resource instead | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | AWS tags to be applied to generated AWS resources of this VPC. | `map(string)` | `null` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | Cidr block of the desired VPC. This value should not be updated, please create a new resource instead | `string` | `"10.0.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_availability_zones"></a> [availability\_zones](#output\_availability\_zones) | List of the Availability Zone names used for the VPC creation |
| <a name="output_cidr_block"></a> [cidr\_block](#output\_cidr\_block) | The CIDR block of the VPC for the association. |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | List of private subnets created this this AWS VPC |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | List of public subnets created this this AWS VPC |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The unique ID of the VPC |
<!-- END_AUTOMATED_TF_DOCS_BLOCK -->
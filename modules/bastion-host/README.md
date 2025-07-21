# Bastion Host

## Introduction

This is a Terraform manifest example for creating a bastion host aws ec2 instance. This example provides a structured configuration template that demonstrates how to deploy vpc and bastion host to your AWS environment by using Terraform.

This example includes:
- A VPC with both public and private subnets.
- An EC2 instance attached to the public subnet of the vpc that allows connection to it so it may access the private network from within it.

## Example Usage

```
############################
# VPC
############################
module "vpc" {
  source = "terraform-redhat/rosa-hcp/rhcs//modules/vpc"

  name_prefix              = "my-vpc"
  availability_zones_count = 1
}

############################
# Bastion instance for connection to the cluster
############################
module "bastion_host" {
  source     = "../../modules/bastion-host"
  prefix     = "my-host"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = [module.vpc.public_subnets[0]]
  ami_id         = aws_ami.rhel9.id
  user_data_file = file("bastion-host-user-data.yaml")
}
```


<!-- BEGIN_AUTOMATED_TF_DOCS_BLOCK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.35.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.35.0 |
| <a name="provider_http"></a> [http](#provider\_http) | n/a |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_instance.bastion_host](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_key_pair.bastion_ssh_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_security_group.bastion_host_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [local_file.bastion_private_ssh_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [time_sleep.bastion_resources_wait](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [tls_private_key.pk](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_ami.rhel9](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [http_http.myip](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | Amazon Machine Image to run the bastion host with | `string` | `null` | no |
| <a name="input_cidr_blocks"></a> [cidr\_blocks](#input\_cidr\_blocks) | CIDR ranges to include as ingress allowed ranges | `list(string)` | `null` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Instance type of the bastion hosts | `string` | `"t2.micro"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix for the name of each AWS resource | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Set of subnet IDs to instantiate a bastion host against | `list(string)` | n/a | yes |
| <a name="input_user_data_file"></a> [user\_data\_file](#input\_user\_data\_file) | User data for proxy configuration | `string` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the AWS VPC resource | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bastion_host_pem_path"></a> [bastion\_host\_pem\_path](#output\_bastion\_host\_pem\_path) | File path of bastion host .pem |
| <a name="output_bastion_host_public_ip"></a> [bastion\_host\_public\_ip](#output\_bastion\_host\_public\_ip) | Bastion Host Public IP |
<!-- END_AUTOMATED_TF_DOCS_BLOCK -->
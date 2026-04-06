# image-mirrors

## Introduction

This Terraform sub-module manages the image mirrors for ROSA HCP clusters. It enables you to efficiently configure image digest mirror sets after cluster deployment. With this module, you can easily set up container image mirroring to redirect image pulls from source registries to mirror registries, enabling zero-egress networking and improved performance.

## Example Usage

```
module "imagemirror" {
  source = "terraform-redhat/rosa-hcp/rhcs//modules/image-mirrors"

  cluster_id      = "cluster-id-123"
  type            = "digest"
  source_registry = "registry.redhat.io"
  mirrors         = ["mirror.example.com"]
}
```

<!-- BEGIN_AUTOMATED_TF_DOCS_BLOCK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_rhcs"></a> [rhcs](#requirement\_rhcs) | >= 1.7.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_rhcs"></a> [rhcs](#provider\_rhcs) | >= 1.7.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [rhcs_image_mirror.image_mirror](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/image_mirror) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | Identifier of the cluster. | `string` | n/a | yes |
| <a name="input_mirrors"></a> [mirrors](#input\_mirrors) | List of mirror registry hostnames. | `list(string)` | n/a | yes |
| <a name="input_source_registry"></a> [source\_registry](#input\_source\_registry) | The source registry hostname. | `string` | n/a | yes |
| <a name="input_type"></a> [type](#input\_type) | The type of the image digest mirror set. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_image_mirror_id"></a> [image\_mirror\_id](#output\_image\_mirror\_id) | The unique identifier of the image mirror. |
<!-- END_AUTOMATED_TF_DOCS_BLOCK -->
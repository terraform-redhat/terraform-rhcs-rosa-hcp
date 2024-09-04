# kubelet-configs

## Introduction

This Terraform sub-module manages the kubelet configs for ROSA HCP clusters. It enables you to efficiently configure kubelet configs after cluster deployment. With this module, you can easily adjust the value of the pod pid limit in the custom KubeletConfig object to allow custom configuration of nodes in a machine pool.

## Example Usage

```
module "kubeletconfig" {
  source = "terraform-redhat/rosa-hcp/rhcs//modules/kubelet-configs"

  cluster_id = "cluster-id-123"
  name = "my-kubelet-config"
  pod_pids_limit = 4096
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
| [rhcs_kubeletconfig.rosa_kubeletconfig](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/kubeletconfig) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | Identifier of the cluster. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the KubeletConfig. | `string` | n/a | yes |
| <a name="input_pod_pids_limit"></a> [pod\_pids\_limit](#input\_pod\_pids\_limit) | Sets the requested podPidsLimit to be applied as part of the custom KubeletConfig. | `number` | `null` | no |

## Outputs

No outputs.
<!-- END_AUTOMATED_TF_DOCS_BLOCK -->
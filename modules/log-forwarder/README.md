# log-forwarder

## Introduction

This Terraform sub-module manages [`rhcs_log_forwarder`](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/log_forwarder) resources for ROSA HCP clusters. It configures forwarding of cluster logs to **either** Amazon S3 **or** Amazon CloudWatch (not both), and selects which applications and/or log forwarder groups to include.

**Provider note:** Use a **terraform-redhat/rhcs** release that includes the `rhcs_log_forwarder` resource (see provider [changelog](https://github.com/terraform-redhat/terraform-provider-rhcs/blob/main/CHANGELOG.md)). The module constraint `>= 1.7.2` matches other submodules; bump the submodule `versions.tf` once the minimum released version that ships this resource is known.

## Tests

From this directory (`modules/log-forwarder`), run:

```bash
terraform init -backend=false
terraform test
```

[`tests/log_forwarder.tftest.hcl`](./tests/log_forwarder.tftest.hcl) uses a mocked `rhcs` provider and covers the module preconditions (exactly one of `s3` / `cloudwatch`, non-empty `applications` or `groups`) plus successful plan cases.

## Example Usage

```
module "cluster_logs_s3" {
  source = "terraform-redhat/rosa-hcp/rhcs//modules/log-forwarder"
  version = "1.7.2"

  cluster_id = module.hcp.cluster_id

  s3 = {
    bucket_name   = "my-cluster-logs"
    bucket_prefix = "rosa-hcp/"
  }

  applications = ["my-app"]
}
```

```
module "cluster_logs_cloudwatch" {
  source = "terraform-redhat/rosa-hcp/rhcs//modules/log-forwarder"
  version = "1.7.2"

  cluster_id = module.hcp.cluster_id

  cloudwatch = {
    log_group_name            = "/rosa/hcp/cluster"
    log_distribution_role_arn = "arn:aws:iam::123456789012:role/LogDistributionRole"
  }

  groups = [
    { id = "audit", version = "1.0" }
  ]
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
| [rhcs_log_forwarder.this](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/log_forwarder) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_applications"></a> [applications](#input\_applications) | List of additional applications to forward logs for. At least one of applications or groups must be non-empty (provider requirement). | `list(string)` | `null` | no |
| <a name="input_cloudwatch"></a> [cloudwatch](#input\_cloudwatch) | CloudWatch destination for log forwarding. Mutually exclusive with s3. See rhcs\_log\_forwarder resource documentation. | <pre>object({<br/>    log_group_name            = string<br/>    log_distribution_role_arn = string<br/>  })</pre> | `null` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | Identifier of the cluster. | `string` | n/a | yes |
| <a name="input_groups"></a> [groups](#input\_groups) | List of log forwarder groups. At least one of applications or groups must be non-empty (provider requirement). | <pre>list(object({<br/>    id      = string<br/>    version = optional(string)<br/>  }))</pre> | `null` | no |
| <a name="input_s3"></a> [s3](#input\_s3) | S3 destination for log forwarding. Mutually exclusive with cloudwatch. See rhcs\_log\_forwarder resource documentation. | <pre>object({<br/>    bucket_name   = string<br/>    bucket_prefix = optional(string)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | Unique identifier of the log forwarder. |
<!-- END_AUTOMATED_TF_DOCS_BLOCK -->
# notification-contacts

## Introduction

This Terraform sub-module manages notification contacts for ROSA HCP clusters. It enables you to configure the set of OCM account usernames that receive cluster notifications for a given cluster's subscription. This resource is authoritative: Terraform manages the full set of notification contacts.

## Example Usage

```
module "notification_contacts" {
  source = "terraform-redhat/rosa-hcp/rhcs//modules/notification-contacts"

  cluster_id = "cluster-id-123"
  contacts   = ["ocm-username-1", "ocm-username-2"]
}
```

<!-- BEGIN_AUTOMATED_TF_DOCS_BLOCK -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_rhcs"></a> [rhcs](#requirement\_rhcs) | >= 1.7.10 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_rhcs"></a> [rhcs](#provider\_rhcs) | >= 1.7.10 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [rhcs_cluster_notification_contacts.this](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs/resources/cluster_notification_contacts) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | Identifier of the cluster. | `string` | n/a | yes |
| <a name="input_contacts"></a> [contacts](#input\_contacts) | Set of OCM account usernames to receive cluster notifications. This resource is authoritative: the full set of notification contacts is managed by Terraform. | `set(string)` | n/a | yes |

## Outputs

No outputs.
<!-- END_AUTOMATED_TF_DOCS_BLOCK -->

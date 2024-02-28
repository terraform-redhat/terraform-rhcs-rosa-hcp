output "account_role_prefix" {
  value       = time_sleep.account_iam_resources_wait.triggers["account_role_prefix"]
  description = "The prefix used for all generated AWS resources."
}

output "account_roles_arn" {
  value       = jsondecode(time_sleep.account_iam_resources_wait.triggers["account_roles_arn"])
  description = "A map of Amazon Resource Names (ARNs) associated with the AWS IAM roles created. The key in the map represents the name of an AWS IAM role, while the corresponding value represents the associated Amazon Resource Name (ARN) of that role."
}

output "path" {
  value       = time_sleep.account_iam_resources_wait.triggers["path"]
  description = "The arn path for the account/operator roles as well as their policies."
}
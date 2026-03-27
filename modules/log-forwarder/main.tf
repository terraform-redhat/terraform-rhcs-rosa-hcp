resource "rhcs_log_forwarder" "this" {
  cluster = var.cluster_id

  s3 = var.s3 != null ? {
    bucket_name   = var.s3.bucket_name
    bucket_prefix = try(var.s3.bucket_prefix, null)
  } : null

  cloudwatch = var.cloudwatch != null ? {
    log_group_name            = var.cloudwatch.log_group_name
    log_distribution_role_arn = var.cloudwatch.log_distribution_role_arn
  } : null

  applications = var.applications
  groups       = var.groups

  lifecycle {
    precondition {
      condition     = (var.s3 != null && var.cloudwatch == null) || (var.s3 == null && var.cloudwatch != null)
      error_message = "Specify exactly one of s3 or cloudwatch for the log forwarder destination."
    }
    precondition {
      condition = (
        length([
          for app in coalesce(var.applications, []) : app
          if trimspace(app) != ""
        ]) > 0
      ) || (
        length([
          for grp in coalesce(var.groups, []) : grp
          if trimspace(grp.id) != ""
        ]) > 0
      )
      error_message = "At least one of applications or groups must be specified with non-empty values."
    }
  }
}

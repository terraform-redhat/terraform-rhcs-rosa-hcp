resource "rhcs_rosa_oidc_config" "oidc_config" {
  managed            = var.managed
  secret_arn         = var.managed ? null : aws_secretsmanager_secret.secret[0].arn
  issuer_url         = var.managed ? null : rhcs_rosa_oidc_config_input.oidc_input[0].issuer_url
  installer_role_arn = var.installer_role_arn
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  url = "https://${rhcs_rosa_oidc_config.oidc_config.oidc_endpoint_url}"

  client_id_list = [
    "openshift",
    "sts.amazonaws.com"
  ]

  tags = var.tags

  thumbprint_list = [rhcs_rosa_oidc_config.oidc_config.thumbprint]
}

resource "aws_s3_bucket" "s3_bucket" {
  count  = var.managed ? 0 : 1
  bucket = rhcs_rosa_oidc_config_input.oidc_input[count.index].bucket_name

  tags = merge(var.tags, {
    red-hat-managed = true
  })
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  count  = var.managed ? 0 : 1
  bucket = aws_s3_bucket.s3_bucket[count.index].id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
  count = var.managed ? 0 : 1

  statement {
    principals {
      identifiers = ["*"]
      type        = "*"
    }
    sid    = "AllowReadPublicAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]

    resources = [
      format("arn:aws:s3:::%s/*", rhcs_rosa_oidc_config_input.oidc_input[count.index].bucket_name),
    ]
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  depends_on = [aws_s3_bucket_public_access_block.public_access_block]
  count      = var.managed ? 0 : 1
  bucket     = aws_s3_bucket.s3_bucket[count.index].id
  policy     = data.aws_iam_policy_document.allow_access_from_another_account[count.index].json
}

resource "rhcs_rosa_oidc_config_input" "oidc_input" {
  count = var.managed ? 0 : 1

  region = data.aws_region.current.region
  prefix = var.oidc_prefix
}

resource "aws_secretsmanager_secret" "secret" {
  count       = var.managed ? 0 : 1
  name        = rhcs_rosa_oidc_config_input.oidc_input[count.index].private_key_secret_name
  description = format("Secret for %s", rhcs_rosa_oidc_config_input.oidc_input[count.index].private_key_secret_name)

  tags = merge(var.tags, {
    red-hat-managed = true
  })
}

resource "aws_secretsmanager_secret_version" "store_in_secret" {
  count         = var.managed ? 0 : 1
  secret_id     = aws_secretsmanager_secret.secret[count.index].id
  secret_string = rhcs_rosa_oidc_config_input.oidc_input[count.index].private_key
}

resource "aws_s3_object" "discover_doc_object" {
  count = var.managed ? 0 : 1

  bucket       = aws_s3_bucket.s3_bucket[count.index].id
  key          = ".well-known/openid-configuration"
  content      = rhcs_rosa_oidc_config_input.oidc_input[count.index].discovery_doc
  content_type = "application/json"

  tags = merge(var.tags, {
    red-hat-managed = true
  })
}

resource "aws_s3_object" "jwks_object" {
  count = var.managed ? 0 : 1

  bucket       = aws_s3_bucket.s3_bucket[count.index].id
  key          = "keys.json"
  content      = rhcs_rosa_oidc_config_input.oidc_input[count.index].jwks
  content_type = "application/json"

  tags = merge(var.tags, {
    red-hat-managed = true
  })
}

data "aws_region" "current" {}

resource "time_sleep" "wait_10_seconds" {
  create_duration  = "10s"
  destroy_duration = "10s"
  triggers = {
    oidc_config_id                         = rhcs_rosa_oidc_config.oidc_config.id
    oidc_endpoint_url                      = rhcs_rosa_oidc_config.oidc_config.oidc_endpoint_url
    oidc_provider_url                      = aws_iam_openid_connect_provider.oidc_provider.url
    discover_doc_object                    = var.managed ? null : aws_s3_object.discover_doc_object[0].checksum_sha1
    s3_object                              = var.managed ? null : aws_s3_object.jwks_object[0].checksum_sha1
    policy_attached_to_bucket              = var.managed ? null : aws_s3_bucket_policy.allow_access_from_another_account[0].bucket
    public_access_block_attached_to_bucket = var.managed ? null : aws_s3_bucket_public_access_block.public_access_block[0].bucket
    secret_arn                             = var.managed ? null : aws_secretsmanager_secret.secret[0].arn
  }
}

resource "null_resource" "unmanaged_vars_validation" {
  lifecycle {
    precondition {
      condition = (var.managed == false && var.installer_role_arn != null) || (var.managed != false && var.installer_role_arn == null)
      error_message = var.managed == true ? (
        "\"installer_role_arn\" variable should not contain a value when using a managed OIDC provider."
        ) : (
        "\"installer_role_arn\" variable should have a value when using an unmanaged OIDC provider."
      )
    }
  }
}

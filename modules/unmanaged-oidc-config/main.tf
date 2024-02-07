module "aws_s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = rhcs_rosa_oidc_config_input.oidc_input.bucket_name
  tags = merge(var.tags, {
    red-hat-managed = true
  })

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false

  attach_policy = true
  policy        = data.aws_iam_policy_document.allow_access_from_another_account.json
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
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
      format("arn:aws:s3:::%s/*", rhcs_rosa_oidc_config_input.oidc_input.bucket_name),
    ]
  }
}

module "aws_secrets_manager" {
  source = "terraform-aws-modules/secrets-manager/aws"

  create      = true
  name        = rhcs_rosa_oidc_config_input.oidc_input.private_key_secret_name
  description = format("Secret for %s", rhcs_rosa_oidc_config_input.oidc_input.private_key_secret_name)

  tags = merge(var.tags, {
    red-hat-managed = true
  })

  secret_string = rhcs_rosa_oidc_config_input.oidc_input.private_key
}

resource "aws_s3_object" "discrover_doc_object" {
  bucket       = module.aws_s3_bucket.s3_bucket_id
  key          = ".well-known/openid-configuration"
  content      = rhcs_rosa_oidc_config_input.oidc_input.discovery_doc
  content_type = "application/json"

  tags = merge(var.tags, {
    red-hat-managed = true
  })
}

resource "aws_s3_object" "jwks_object" {
  bucket       = module.aws_s3_bucket.s3_bucket_id
  key          = "keys.json"
  content      = rhcs_rosa_oidc_config_input.oidc_input.jwks
  content_type = "application/json"

  tags = merge(var.tags, {
    red-hat-managed = true
  })
}

resource "rhcs_rosa_oidc_config_input" "oidc_input" {
  region = data.aws_region.current.name
}

data "aws_region" "current" {}

data "tls_certificate" "github_oidc" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_oidc.certificates[0].sha1_fingerprint]
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_oidc_provider_arn
  role_name         = var.role_name != "" ? var.role_name : "${var.project_name}-gha-oidc-frontend-${var.environment}"
  use_cloudfront    = trimspace(var.cloudfront_distribution_arn) != ""
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo_owner}/${var.github_repo_name}:ref:refs/heads/${var.github_branch}"]
    }
  }
}

resource "aws_iam_role" "github_actions_frontend" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "permissions" {
  statement {
    sid = "S3BucketReadList"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]

    resources = [
      var.s3_bucket_arn
    ]
  }

  statement {
    sid = "S3ObjectWriteReadDelete"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${var.s3_bucket_arn}/*"
    ]
  }

  dynamic "statement" {
    for_each = local.use_cloudfront ? [1] : []

    content {
      sid = "CloudFrontInvalidate"

      actions = [
        "cloudfront:CreateInvalidation",
        "cloudfront:GetDistribution",
        "cloudfront:GetInvalidation"
      ]

      resources = [
        var.cloudfront_distribution_arn
      ]
    }
  }
}

resource "aws_iam_role_policy" "github_actions_frontend" {
  role   = aws_iam_role.github_actions_frontend.id
  policy = data.aws_iam_policy_document.permissions.json
}

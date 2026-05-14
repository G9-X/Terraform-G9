locals {
  use_custom_domain      = trimspace(var.domain_name) != ""
  has_acm_certificate    = trimspace(var.acm_certificate_arn) != ""
  use_cloudfront         = var.enable_cloudfront
  cloudfront_aliases     = local.use_custom_domain && local.has_acm_certificate && local.use_cloudfront ? [trimsuffix(var.domain_name, ".")] : []
  route53_to_cloudfront  = local.use_custom_domain && local.has_acm_certificate && local.use_cloudfront
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# -----------------------------
# Static frontend on private S3 + CloudFront
# -----------------------------
resource "aws_s3_bucket" "static_site" {
  bucket = "${var.project_name}-static-${random_string.suffix.result}"
}

resource "aws_s3_bucket_ownership_controls" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "static_site" {
  count                             = local.use_cloudfront ? 1 : 0
  name                              = "${var.project_name}-oac-${var.environment}"
  description                       = "CloudFront OAC for private S3 static site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  count = local.use_cloudfront ? 1 : 0
  name  = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host_header" {
  count = local.use_cloudfront ? 1 : 0
  name  = "Managed-AllViewerExceptHostHeader"
}

data "aws_lb" "backend" {
  name = "${var.project_name}-alb-${replace(var.environment, "-static", "")}"
}

resource "aws_cloudfront_distribution" "static_site" {
  count   = local.use_cloudfront ? 1 : 0
  enabled = true

  aliases = local.cloudfront_aliases

  origin {
    domain_name              = aws_s3_bucket.static_site.bucket_regional_domain_name
    origin_id                = "s3-${aws_s3_bucket.static_site.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.static_site[0].id

    s3_origin_config {
      origin_access_identity = ""
    }
  }

  origin {
    domain_name = data.aws_lb.backend.dns_name
    origin_id   = "alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  ordered_cache_behavior {
    path_pattern     = "/api/*"
    target_origin_id = "alb"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled[0].id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header[0].id
  }

  default_cache_behavior {
    target_origin_id       = "s3-${aws_s3_bucket.static_site.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = !local.has_acm_certificate
    acm_certificate_arn            = local.has_acm_certificate ? var.acm_certificate_arn : null
    ssl_support_method             = local.has_acm_certificate ? "sni-only" : null
    minimum_protocol_version       = local.has_acm_certificate ? "TLSv1.2_2021" : null
  }

  default_root_object = var.index_document

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/${var.index_document}"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/${var.index_document}"
    error_caching_min_ttl = 0
  }

  depends_on = [
    aws_s3_bucket_ownership_controls.static_site,
    aws_s3_bucket_public_access_block.static_site
  ]
}

data "aws_iam_policy_document" "allow_cloudfront_read" {
  count = local.use_cloudfront ? 1 : 0

  statement {
    sid = "AllowCloudFrontServicePrincipalReadOnly"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = [
      "${aws_s3_bucket.static_site.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.static_site[0].arn]
    }
  }
}

resource "aws_s3_bucket_policy" "static_site" {
  count  = local.use_cloudfront ? 1 : 0
  bucket = aws_s3_bucket.static_site.id
  policy = data.aws_iam_policy_document.allow_cloudfront_read[0].json
}

resource "aws_route53_record" "site_alias_cloudfront" {
  count   = local.route53_to_cloudfront ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = trimsuffix(var.domain_name, ".")
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.static_site[0].domain_name
    zone_id                = aws_cloudfront_distribution.static_site[0].hosted_zone_id
    evaluate_target_health = false
  }
}

module "github_actions_oidc_frontend" {
  count  = var.enable_github_actions_oidc_frontend ? 1 : 0
  source = "../module/GitHubActionsOIDCFrontend"

  project_name                = var.project_name
  environment                 = var.environment
  aws_region                  = var.aws_region
  create_oidc_provider        = var.create_github_oidc_provider
  existing_oidc_provider_arn  = var.existing_github_oidc_provider_arn
  role_name                   = var.github_actions_role_name_frontend
  github_repo_owner           = var.github_repo_owner
  github_repo_name            = var.github_repo_name
  github_branch               = var.github_branch
  s3_bucket_arn               = aws_s3_bucket.static_site.arn
  cloudfront_distribution_arn = local.use_cloudfront ? aws_cloudfront_distribution.static_site[0].arn : ""
}

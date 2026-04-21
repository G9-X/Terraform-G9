output "static_bucket_name" {
  description = "S3 bucket name for static frontend"
  value       = aws_s3_bucket.static_site.id
}

output "static_bucket_arn" {
  description = "S3 bucket ARN for static frontend"
  value       = aws_s3_bucket.static_site.arn
}

output "website_url" {
  description = "Public website URL"
  value       = local.route53_to_cloudfront ? "https://${trimsuffix(var.domain_name, ".")}" : (local.use_cloudfront ? "https://${aws_cloudfront_distribution.static_site[0].domain_name}" : null)
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID when enabled"
  value       = local.use_cloudfront ? aws_cloudfront_distribution.static_site[0].id : null
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name when enabled"
  value       = local.use_cloudfront ? aws_cloudfront_distribution.static_site[0].domain_name : null
}

output "frontend_github_actions_role_arn" {
  description = "Dedicated frontend GitHub Actions OIDC role ARN"
  value       = var.enable_github_actions_oidc_frontend ? module.github_actions_oidc_frontend[0].iam_role_arn : null
}

output "frontend_github_actions_role_name" {
  description = "Dedicated frontend GitHub Actions OIDC role name"
  value       = var.enable_github_actions_oidc_frontend ? module.github_actions_oidc_frontend[0].iam_role_name : null
}

output "github_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN used by frontend deploy role"
  value       = var.enable_github_actions_oidc_frontend ? module.github_actions_oidc_frontend[0].oidc_provider_arn : null
}

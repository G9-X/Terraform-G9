variable "project_name" {
  description = "Project name used in tags and naming"
  type        = string
  default     = "xbrain"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "us-dev-static"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "domain_name" {
  description = "Optional custom subdomain for S3 website CNAME (example: app.example.com)"
  type        = string
  default     = ""
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for domain_name"
  type        = string
  default     = ""
}

variable "index_document" {
  description = "Default index document"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Error document used by S3 website hosting"
  type        = string
  default     = "index.html"
}

variable "enable_cloudfront" {
  description = "Enable CloudFront in front of S3 static website"
  type        = bool
  default     = true
}

variable "acm_certificate_arn" {
  description = "Optional ACM certificate ARN in us-west-2 for CloudFront custom domain"
  type        = string
  default     = ""
}

variable "enable_github_actions_oidc_frontend" {
  description = "Create dedicated GitHub Actions OIDC role for frontend deployment"
  type        = bool
  default     = true
}

variable "create_github_oidc_provider" {
  description = "Create IAM OIDC provider for GitHub Actions in this account"
  type        = bool
  default     = false
}

variable "existing_github_oidc_provider_arn" {
  description = "Existing IAM OIDC provider ARN for GitHub Actions (required when create_github_oidc_provider is false)"
  type        = string
  default     = ""
}

variable "github_actions_role_name_frontend" {
  description = "Optional IAM role name for frontend GitHub Actions OIDC"
  type        = string
  default     = ""
}

variable "github_repo_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = ""
}

variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
  default     = ""
}

variable "github_branch" {
  description = "GitHub branch allowed to assume frontend OIDC role"
  type        = string
  default     = "main"
}

variable "kms_key_arn" {
  description = "KMS key ARN for S3 encryption. If empty, uses AES256."
  type        = string
  default     = ""
}

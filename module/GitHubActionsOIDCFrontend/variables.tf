variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "create_oidc_provider" {
  type    = bool
  default = true
}

variable "existing_oidc_provider_arn" {
  type    = string
  default = ""

  validation {
    condition     = var.create_oidc_provider || length(trimspace(var.existing_oidc_provider_arn)) > 0
    error_message = "Set existing_oidc_provider_arn when create_oidc_provider is false."
  }
}

variable "role_name" {
  type    = string
  default = ""
}

variable "github_repo_owner" {
  type = string
}

variable "github_repo_name" {
  type = string
}

variable "github_branch" {
  type    = string
  default = "main"
}

variable "s3_bucket_arn" {
  type = string
}

variable "cloudfront_distribution_arn" {
  type    = string
  default = ""
}

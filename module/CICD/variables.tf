variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "enable_create_github_connection" {
  type    = bool
  default = false
}

variable "github_connection_name" {
  type    = string
  default = ""
}

variable "github_connection_provider_type" {
  type    = string
  default = "GitHub"
}

variable "github_connection_arn" {
  type = string

  validation {
    condition     = var.enable_create_github_connection || length(trimspace(var.github_connection_arn)) > 0
    error_message = "Set github_connection_arn when enable_create_github_connection is false."
  }
}

variable "github_repo_owner" {
  type = string
}

variable "github_repo_name" {
  type = string
}

variable "github_branch" {
  type    = string
  default = "develop"
}

variable "buildspec_path" {
  type    = string
  default = ".github/buildspec/backend-codepipeline.yml"
}

variable "codebuild_image" {
  type    = string
  default = "aws/codebuild/standard:7.0"
}

variable "codebuild_compute_type" {
  type    = string
  default = "BUILD_GENERAL1_MEDIUM"
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "build_security_group_id" {
  type = string
}

variable "ecr_repository_name" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "ecs_task_family" {
  type = string
}

variable "backend_container_name" {
  type    = string
  default = "backend"
}

variable "backend_db_connection_string" {
  type      = string
  sensitive = true
}

variable "ecs_task_execution_role_arn" {
  type = string
}

variable "ecs_task_role_arn" {
  type = string
}

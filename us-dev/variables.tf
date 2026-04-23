variable "project_name" {
  type    = string
  default = "xbrain"
}

variable "environment" {
  type    = string
  default = "us-dev"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "vpc_cidr" {
  type    = string
  default = "10.50.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.50.1.0/24", "10.50.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  type    = list(string)
  default = ["10.50.11.0/24", "10.50.12.0/24"]
}

variable "private_data_subnet_cidrs" {
  type    = list(string)
  default = ["10.50.21.0/24", "10.50.22.0/24"]
}

variable "backend_port" {
  type    = number
  default = 8080
}

variable "backend_cpu" {
  type    = number
  default = 256
}

variable "backend_memory" {
  type    = number
  default = 512
}

variable "backend_desired_count" {
  type    = number
  default = 0
}

variable "ecs_instance_type" {
  type    = string
  default = "t3.small"
}

variable "ecs_ec2_min_size" {
  type    = number
  default = 1
}

variable "ecs_ec2_max_size" {
  type    = number
  default = 2
}

variable "ecs_ec2_desired_capacity" {
  type    = number
  default = 1
}

variable "backend_image_tag" {
  type    = string
  default = "latest"
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "ecr_image_keep_count" {
  type    = number
  default = 20
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.small"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_max_allocated_storage" {
  type    = number
  default = 100
}

variable "db_engine" {
  type    = string
  default = "mysql"
}

variable "db_engine_version" {
  type    = string
  default = "8.0"
}

variable "db_multi_az" {
  type    = bool
  default = true
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "jwt_secret_key" {
  type      = string
  sensitive = true
}

variable "cloudinary_cloud_name" {
  type = string
}

variable "cloudinary_api_key" {
  type      = string
  sensitive = true
}

variable "cloudinary_api_secret" {
  type      = string
  sensitive = true
}

variable "stripe_secret_key" {
  type      = string
  sensitive = true
}

variable "stripe_publishable_key" {
  type      = string
  sensitive = true
}

variable "stripe_webhook_secret" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type    = string
  default = "xbrain"
}

variable "enable_rds" {
  type    = bool
  default = true
}

variable "enable_github_actions_oidc" {
  type    = bool
  default = true
}

variable "create_github_oidc_provider" {
  type        = bool
  description = "Create IAM OIDC provider for GitHub Actions in this account"
  default     = true
}

variable "existing_github_oidc_provider_arn" {
  type        = string
  description = "Existing IAM OIDC provider ARN for GitHub Actions (used when create_github_oidc_provider = false)"
  default     = ""
}

variable "github_actions_role_name" {
  type        = string
  description = "Optional IAM role name for GitHub Actions OIDC"
  default     = ""
}

variable "github_repo_owner" {
  type        = string
  description = "GitHub repository owner"
  default     = ""
}

variable "github_repo_name" {
  type        = string
  description = "GitHub repository name"
  default     = ""
}

variable "github_branch" {
  type        = string
  description = "Git branch allowed to assume GitHub Actions OIDC role"
  default     = "develop"
}

variable "backend_container_name" {
  type        = string
  description = "Container name inside ECS task definition"
  default     = "backend"
}

variable "enable_lambda_bedrock" {
  type    = bool
  default = false
}

variable "bedrock_model_id" {
  type    = string
}

variable "bedrock_region" {
  type    = string
  default = "us-west-2"
}

variable "lambda_timeout" {
  type    = number
  default = 30
}

variable "lambda_memory" {
  type    = number
  default = 256
}

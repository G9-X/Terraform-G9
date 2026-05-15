variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "private_app_subnet_ids" {
  type = list(string)
}

variable "backend_security_group_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "ecr_repository_url" {
  type = string
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "container_port" {
  type    = number
  default = 8080
}

variable "cpu" {
  type    = number
  default = 256
}

variable "memory" {
  type    = number
  default = 512
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "ec2_instance_type" {
  type    = string
  default = "t3.small"
}

variable "ec2_min_size" {
  type    = number
  default = 1
}

variable "ec2_max_size" {
  type    = number
  default = 2
}

variable "ec2_desired_capacity" {
  type    = number
  default = 1
}

variable "db_endpoint" {
  type = string
}

variable "db_port" {
  type    = number
  default = 3306
}

variable "db_name" {
  type    = string
  default = "xbrain"
}

variable "db_user" {
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

# ═══════════════════════════════════════
# EFS Integration (Week 5 Hardening)
# ═══════════════════════════════════════

variable "efs_file_system_id" {
  description = "EFS File System ID to mount into backend containers"
  type        = string
  default     = ""
}

variable "efs_access_point_id" {
  description = "EFS Access Point ID (POSIX user 1654)"
  type        = string
  default     = ""
}

variable "efs_file_system_arn" {
  description = "EFS File System ARN for IAM policy"
  type        = string
  default     = ""
}

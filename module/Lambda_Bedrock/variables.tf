variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "bedrock_model_id" {
  type        = string
  description = "Bedrock foundation model ID"
}

variable "bedrock_region" {
  type        = string
  description = "AWS region for Bedrock runtime client (model must be enabled in this region)"
}

variable "lambda_timeout" {
  type    = number
  default = 30
}

variable "lambda_memory" {
  type    = number
  default = 256
}

variable "log_retention_days" {
  type    = number
  default = 14
}

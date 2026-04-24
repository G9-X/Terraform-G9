variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. us-dev)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "knowledge_base_id" {
  description = "Bedrock Knowledge Base ID to query"
  type        = string
}

variable "model_id" {
  description = "Bedrock model ID for answer generation (e.g. DeepSeek R1)"
  type        = string
  default     = "us.deepseek.deepseek-r1-v1:0"
}

variable "allowed_origin" {
  description = "CORS allowed origin (frontend domain)"
  type        = string
  default     = "https://app.group9.id.vn"
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds (API Gateway limit is 29s)"
  type        = number
  default     = 29
}

variable "lambda_memory" {
  description = "Lambda memory in MB"
  type        = number
  default     = 256
}

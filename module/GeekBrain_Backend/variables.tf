variable "project" { type = string }
variable "tags" { type = map(string) }
variable "region" { type = string }
variable "account_id" { type = string }

variable "llm_model_id" { type = string }
variable "knowledge_base_id" { type = string }

variable "retrieval_k" {
  type    = number
  default = 10
}


variable "private_subnet_ids" {
  description = "Private app subnet IDs for Action Group Lambda VPC config"
  type        = list(string)
  default     = []
}

variable "lambda_sg_id" {
  description = "Security group ID for Lambda functions"
  type        = string
  default     = ""
}

# DB vars are optional — PostgreSQL not deployed yet
variable "db_host" {
  type    = string
  default = ""
}

variable "db_name" {
  type    = string
  default = ""
}

variable "db_user" {
  type    = string
  default = ""
}

variable "db_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "api_throttle_rate_limit" {
  description = "API Gateway throttle rate limit (requests/second)"
  type        = number
  default     = 10
}

variable "api_throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 20
}

variable "api_quota_limit" {
  description = "API Gateway daily quota limit"
  type        = number
  default     = 1000
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for S3 encryption"
  type        = string
}

variable "log_exports" {
  description = "Map of log groups to export via Firehose. Key = stream name, value = log_group_name + s3_prefix"
  type = map(object({
    log_group_name = string
    s3_prefix      = string
  }))
  default = {}
}

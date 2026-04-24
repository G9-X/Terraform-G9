variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. us-dev)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for Bedrock and OpenSearch Serverless"
  type        = string
}

variable "embedding_model_id" {
  description = "Bedrock foundation model ID for embeddings"
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}

variable "embedding_dimension" {
  description = "Vector dimension for embedding model (Titan v2 supports 256, 512, 1024)"
  type        = number
  default     = 1024
}

variable "collection_name_suffix" {
  description = "Suffix appended to project_name for the OpenSearch Serverless collection name"
  type        = string
  default     = "kb"
}

variable "vector_index_name" {
  description = "Name of the vector index inside the OpenSearch Serverless collection"
  type        = string
  default     = "bedrock-kb-default-index"
}

variable "additional_access_policy_principals" {
  description = "Extra IAM principal ARNs granted data-level access to the AOSS collection (e.g. your IAM user ARN for running the index-creation script)"
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "KMS key ARN for S3 encryption. If empty, uses AES256."
  type        = string
  default     = ""
}

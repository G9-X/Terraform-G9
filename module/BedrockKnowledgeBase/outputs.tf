output "knowledge_base_id" {
  description = "Bedrock Knowledge Base ID"
  value       = aws_bedrockagent_knowledge_base.main.id
}

output "knowledge_base_arn" {
  description = "Bedrock Knowledge Base ARN"
  value       = aws_bedrockagent_knowledge_base.main.arn
}

output "data_source_id" {
  description = "Bedrock S3 Data Source ID"
  value       = aws_bedrockagent_data_source.s3.data_source_id
}

output "s3_data_bucket_name" {
  description = "S3 bucket name for KB document storage"
  value       = aws_s3_bucket.kb_data.id
}

output "s3_data_bucket_arn" {
  description = "S3 bucket ARN for KB document storage"
  value       = aws_s3_bucket.kb_data.arn
}

output "opensearch_collection_endpoint" {
  description = "OpenSearch Serverless collection endpoint URL"
  value       = aws_opensearchserverless_collection.kb.collection_endpoint
}

output "opensearch_collection_arn" {
  description = "OpenSearch Serverless collection ARN"
  value       = aws_opensearchserverless_collection.kb.arn
}

output "opensearch_collection_name" {
  description = "OpenSearch Serverless collection name"
  value       = aws_opensearchserverless_collection.kb.name
}

output "bedrock_role_arn" {
  description = "IAM role ARN assumed by Bedrock Knowledge Base service"
  value       = aws_iam_role.bedrock_kb.arn
}

output "vector_index_name" {
  description = "Name of the vector index (must be created manually after first apply)"
  value       = var.vector_index_name
}

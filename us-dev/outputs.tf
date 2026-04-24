output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecs_cluster_name" {
  value = module.ecs_backend.cluster_name
}

output "ecs_service_name" {
  value = module.ecs_backend.service_name
}

output "ecs_backend_db_connection_secret_arn" {
  value = module.ecs_backend.db_connection_secret_arn
}

output "ecs_backend_jwt_secret_key_secret_arn" {
  value = module.ecs_backend.jwt_secret_key_secret_arn
}

output "ecs_backend_cloudinary_cloud_name_secret_arn" {
  value = module.ecs_backend.cloudinary_cloud_name_secret_arn
}

output "ecs_backend_cloudinary_api_key_secret_arn" {
  value = module.ecs_backend.cloudinary_api_key_secret_arn
}

output "ecs_backend_cloudinary_api_secret_secret_arn" {
  value = module.ecs_backend.cloudinary_api_secret_secret_arn
}

output "ecs_backend_stripe_secret_key_secret_arn" {
  value = module.ecs_backend.stripe_secret_key_secret_arn
}

output "ecs_backend_stripe_publishable_key_secret_arn" {
  value = module.ecs_backend.stripe_publishable_key_secret_arn
}

output "ecs_backend_stripe_webhook_secret_secret_arn" {
  value = module.ecs_backend.stripe_webhook_secret_secret_arn
}

output "ecs_capacity_provider_name" {
  value = module.ecs_backend.capacity_provider_name
}

output "ecs_autoscaling_group_name" {
  value = module.ecs_backend.autoscaling_group_name
}

output "rds_endpoint" {
  value = var.enable_rds ? module.database_mysql[0].db_endpoint : null
}

output "rds_port" {
  value = var.enable_rds ? module.database_mysql[0].db_port : null
}

output "github_actions_role_arn" {
  value = var.enable_github_actions_oidc ? module.github_actions_oidc[0].iam_role_arn : null
}

output "github_actions_role_name" {
  value = var.enable_github_actions_oidc ? module.github_actions_oidc[0].iam_role_name : null
}

output "github_oidc_provider_arn" {
  value = var.enable_github_actions_oidc ? module.github_actions_oidc[0].oidc_provider_arn : null
}

output "cloudwatch_log_group_name" {
  value = module.ecs_backend.cloudwatch_log_group_name
}

# ─── Bedrock Knowledge Base ───

output "bedrock_knowledge_base_id" {
  description = "Bedrock Knowledge Base ID"
  value       = module.bedrock_knowledge_base.knowledge_base_id
}

output "bedrock_data_source_id" {
  description = "Bedrock S3 Data Source ID"
  value       = module.bedrock_knowledge_base.data_source_id
}

output "bedrock_s3_data_bucket_name" {
  description = "S3 bucket name for KB documents"
  value       = module.bedrock_knowledge_base.s3_data_bucket_name
}

output "bedrock_opensearch_collection_endpoint" {
  description = "OpenSearch Serverless collection endpoint"
  value       = module.bedrock_knowledge_base.opensearch_collection_endpoint
}

output "bedrock_opensearch_collection_name" {
  description = "OpenSearch Serverless collection name"
  value       = module.bedrock_knowledge_base.opensearch_collection_name
}

output "bedrock_vector_index_name" {
  description = "Vector index name (create manually after first apply)"
  value       = module.bedrock_knowledge_base.vector_index_name
}

# ─── Bedrock Chat API ───

output "chat_api_url" {
  description = "Chat API endpoint URL (POST /chat)"
  value       = module.bedrock_chat.api_gateway_url
}

output "chat_lambda_function_name" {
  description = "Chat Lambda function name"
  value       = module.bedrock_chat.lambda_function_name
}

# ─── KMS ───

output "kms_key_arn" {
  description = "KMS CMK ARN (use in us-dev-static for S3 frontend encryption)"
  value       = module.kms.key_arn
}

# ─── Centralized Logs ───

output "log_bucket_name" {
  description = "S3 log bucket name"
  value       = module.centralized_logs.bucket_name
}

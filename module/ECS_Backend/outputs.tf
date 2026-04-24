output "cluster_name" {
  value = aws_ecs_cluster.backend.name
}

output "service_name" {
  value = aws_ecs_service.backend.name
}

output "task_family" {
  value = aws_ecs_task_definition.backend.family
}

output "task_execution_role_arn" {
  value = aws_iam_role.execution_role.arn
}

output "task_role_arn" {
  value = aws_iam_role.task_role.arn
}

output "db_connection_secret_arn" {
  value = aws_secretsmanager_secret.backend_db_connection.arn
}

output "jwt_secret_key_secret_arn" {
  value = aws_secretsmanager_secret.backend_jwt_secret_key.arn
}

output "cloudinary_cloud_name_secret_arn" {
  value = aws_secretsmanager_secret.backend_cloudinary_cloud_name.arn
}

output "cloudinary_api_key_secret_arn" {
  value = aws_secretsmanager_secret.backend_cloudinary_api_key.arn
}

output "cloudinary_api_secret_secret_arn" {
  value = aws_secretsmanager_secret.backend_cloudinary_api_secret.arn
}

output "stripe_secret_key_secret_arn" {
  value = aws_secretsmanager_secret.backend_stripe_secret_key.arn
}

output "stripe_publishable_key_secret_arn" {
  value = aws_secretsmanager_secret.backend_stripe_publishable_key.arn
}

output "stripe_webhook_secret_secret_arn" {
  value = aws_secretsmanager_secret.backend_stripe_webhook_secret.arn
}

output "capacity_provider_name" {
  value = aws_ecs_capacity_provider.ec2.name
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.ecs.name
}

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.backend.name
}

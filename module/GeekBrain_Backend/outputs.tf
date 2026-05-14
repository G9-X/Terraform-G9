output "api_gateway_url" {
  description = "API Gateway invoke URL"
  value       = aws_api_gateway_stage.prod.invoke_url
}

output "lambda_function_name" {
  description = "Main Lambda function name"
  value       = aws_lambda_function.chat.function_name
}

output "api_key_value" {
  description = "API Key value for chat endpoint"
  value       = aws_api_gateway_api_key.chat.value
  sensitive   = true
}

output "api_key_id" {
  description = "API Key ID"
  value       = aws_api_gateway_api_key.chat.id
}

output "usage_plan_id" {
  description = "Usage Plan ID"
  value       = aws_api_gateway_usage_plan.chat.id
}

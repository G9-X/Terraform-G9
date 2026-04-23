output "api_gateway_url" {
  description = "Full URL for the chat API endpoint"
  value       = "${aws_apigatewayv2_stage.prod.invoke_url}/chat"
}

output "api_gateway_id" {
  description = "API Gateway HTTP API ID"
  value       = aws_apigatewayv2_api.chat.id
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.chat.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.chat.arn
}

output "lambda_role_arn" {
  description = "IAM role ARN used by Lambda"
  value       = aws_iam_role.lambda_chat.arn
}

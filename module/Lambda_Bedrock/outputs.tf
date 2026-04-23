output "lambda_function_arn" {
  value = aws_lambda_function.bedrock.arn
}

output "lambda_function_name" {
  value = aws_lambda_function.bedrock.function_name
}

output "api_gateway_url" {
  value = aws_apigatewayv2_stage.lambda.invoke_url
}

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.lambda.name
}

output "lambda_execution_role_arn" {
  value = aws_iam_role.lambda_execution.arn
}

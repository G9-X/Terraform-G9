output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "backend_security_group_id" {
  value = aws_security_group.backend.id
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}

output "lambda_security_group_id" {
  value = aws_security_group.lambda.id
}

output "endpoint_security_group_id" {
  value = aws_security_group.endpoint.id
}


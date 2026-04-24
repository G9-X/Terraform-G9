output "bucket_name" {
  description = "Log bucket name"
  value       = aws_s3_bucket.logs.id
}

output "bucket_arn" {
  description = "Log bucket ARN"
  value       = aws_s3_bucket.logs.arn
}

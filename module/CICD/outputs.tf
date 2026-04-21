output "codepipeline_name" {
  value = aws_codepipeline.backend.name
}

output "codebuild_project_name" {
  value = aws_codebuild_project.backend.name
}

output "artifacts_bucket_name" {
  value = aws_s3_bucket.artifacts.id
}

output "github_connection_arn" {
  value = local.github_connection_arn_effective
}

output "github_connection_status" {
  value = var.enable_create_github_connection ? aws_codestarconnections_connection.github[0].connection_status : "EXTERNAL"
}

output "iam_role_arn" {
  value = aws_iam_role.github_actions_frontend.arn
}

output "iam_role_name" {
  value = aws_iam_role.github_actions_frontend.name
}

output "oidc_provider_arn" {
  value = local.oidc_provider_arn
}

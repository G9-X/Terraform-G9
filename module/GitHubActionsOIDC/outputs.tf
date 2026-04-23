output "iam_role_arn" {
  value = aws_iam_role.github_actions.arn
}

output "iam_role_name" {
  value = aws_iam_role.github_actions.name
}

output "oidc_provider_arn" {
  value = local.oidc_provider_arn
}

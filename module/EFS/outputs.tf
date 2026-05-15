output "file_system_id" {
  value = aws_efs_file_system.main.id
}

output "file_system_arn" {
  value = aws_efs_file_system.main.arn
}

output "access_point_id" {
  value = aws_efs_access_point.backend.id
}

output "security_group_id" {
  value = aws_security_group.efs.id
}

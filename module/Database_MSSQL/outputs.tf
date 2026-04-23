output "db_endpoint" {
  value = aws_db_instance.mssql.address
}

output "db_port" {
  value = aws_db_instance.mssql.port
}

output "db_identifier" {
  value = aws_db_instance.mssql.id
}

resource "aws_db_subnet_group" "mssql" {
  name       = "${var.project_name}-mssql-subnet-${var.environment}"
  subnet_ids = var.private_data_subnet_ids
}

resource "aws_db_instance" "mssql" {
  identifier              = "${var.project_name}-mssql-${var.environment}"
  engine                  = var.db_engine
  engine_version          = var.db_engine_version
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  max_allocated_storage   = var.db_max_allocated_storage
  storage_type            = "gp3"
  storage_encrypted       = true
  username                = var.db_username
  password                = var.db_password
  port                    = 1433
  publicly_accessible     = false
  multi_az                = var.multi_az
  db_subnet_group_name    = aws_db_subnet_group.mssql.name
  vpc_security_group_ids  = [var.rds_security_group_id]
  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = var.skip_final_snapshot
  apply_immediately       = true
  license_model           = "license-included"
}

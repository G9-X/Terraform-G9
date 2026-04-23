resource "aws_db_subnet_group" "mysql" {
  name       = "${var.project_name}-mysql-subnet-${var.environment}"
  subnet_ids = var.private_data_subnet_ids
}

resource "aws_db_instance" "mysql" {
  identifier              = "${var.project_name}-mysql-${var.environment}"
  engine                  = var.db_engine
  engine_version          = var.db_engine_version
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  max_allocated_storage   = var.db_max_allocated_storage
  storage_type            = "gp3"
  storage_encrypted       = true
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  port                    = 3306
  publicly_accessible     = false
  multi_az                = var.multi_az
  db_subnet_group_name    = aws_db_subnet_group.mysql.name
  vpc_security_group_ids  = [var.rds_security_group_id]
  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = var.skip_final_snapshot
  apply_immediately       = true
}

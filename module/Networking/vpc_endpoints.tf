# ═══════════════════════════════════════
# VPC Endpoints cho ECS Backend
# ═══════════════════════════════════════

# S3 Gateway Endpoint (Lấy Docker image layer và EFS backup)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.public.id,
    aws_route_table.private_app.id,
    aws_route_table.private_data.id
  ]

  tags = {
    Name = "${var.project_name}-s3-endpoint-${var.environment}"
  }
}

# ECR API
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_app[*].id
  security_group_ids  = [var.vpc_endpoints_security_group_id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-ecr-api-endpoint-${var.environment}"
  }
}

# ECR DKR
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_app[*].id
  security_group_ids  = [var.vpc_endpoints_security_group_id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-ecr-dkr-endpoint-${var.environment}"
  }
}

# CloudWatch Logs
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_app[*].id
  security_group_ids  = [var.vpc_endpoints_security_group_id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-logs-endpoint-${var.environment}"
  }
}

# Secrets Manager
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_app[*].id
  security_group_ids  = [var.vpc_endpoints_security_group_id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-secretsmanager-endpoint-${var.environment}"
  }
}

# EFS Endpoint (Tối ưu cho MH3)
resource "aws_vpc_endpoint" "efs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.elasticfilesystem"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_app[*].id
  security_group_ids  = [var.vpc_endpoints_security_group_id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-efs-endpoint-${var.environment}"
  }
}

# SSM Endpoint (Cho phép ECS Exec Session Manager)
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_app[*].id
  security_group_ids  = [var.vpc_endpoints_security_group_id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-ssm-endpoint-${var.environment}"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_app[*].id
  security_group_ids  = [var.vpc_endpoints_security_group_id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-ssmmessages-endpoint-${var.environment}"
  }
}

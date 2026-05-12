resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg-${var.environment}"
  description = "ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.alb_ingress_cidrs
    description = "HTTP ingress"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.alb_ingress_cidrs
    description = "HTTPS ingress"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }
}

resource "aws_security_group" "backend" {
  name        = "${var.project_name}-backend-sg-${var.environment}"
  description = "Backend ECS task security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.backend_port
    to_port         = var.backend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Backend traffic from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg-${var.environment}"
  description = "RDS MySQL security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
    description     = "MySQL from backend SG"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }
}

# ═══════════════════════════════════════
# GeekBrain Lambda SG (Action Group + Seed Lambda)
# ═══════════════════════════════════════

resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-lambda-sg-${var.environment}"
  description = "Security group for GeekBrain Lambda functions (Action Group)"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.project_name}-lambda-sg-${var.environment}"
  }
}

# ═══════════════════════════════════════
# VPC Endpoint SG (HTTPS from Lambda)
# ═══════════════════════════════════════

resource "aws_security_group" "endpoint" {
  name        = "${var.project_name}-endpoint-sg-${var.environment}"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
    description     = "Allow HTTPS from Lambda SG"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.project_name}-endpoint-sg-${var.environment}"
  }
}


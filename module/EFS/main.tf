# ═══════════════════════════════════════
# EFS File System + Access Point
# (Week 5 Hardening - Shared Storage)
# ═══════════════════════════════════════

resource "aws_efs_file_system" "main" {
  creation_token = "${var.project_name}-efs-${var.environment}"
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name        = "${var.project_name}-efs-${var.environment}"
    Environment = var.environment
    Backup      = "true"
  }
}

# Security Group cho EFS (cho phép NFS từ Backend SG)
resource "aws_security_group" "efs" {
  name        = "${var.project_name}-efs-sg-${var.environment}"
  description = "EFS mount target security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.backend_security_group_id]
    description     = "NFS from Backend ECS tasks"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.project_name}-efs-sg-${var.environment}"
  }
}

# Mount Target trên mỗi Private App Subnet
resource "aws_efs_mount_target" "main" {
  count = length(var.private_app_subnet_ids)

  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.private_app_subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

# Access Point (POSIX user 1654 cho .NET App)
resource "aws_efs_access_point" "backend" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    uid = 1654
    gid = 1654
  }

  root_directory {
    path = "/app-data"

    creation_info {
      owner_uid   = 1654
      owner_gid   = 1654
      permissions = "755"
    }
  }

  tags = {
    Name = "ap-merxly-backend"
  }
}

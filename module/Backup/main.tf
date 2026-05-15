# ═══════════════════════════════════════
# AWS Backup: Vault + Plan + Resource Assignment
# (Week 5 Hardening - Backup & Restore)
# ═══════════════════════════════════════

# --- IAM Role cho AWS Backup ---
data "aws_iam_policy_document" "backup_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backup" {
  name               = "AWSBackupDefaultServiceRole"
  assume_role_policy = data.aws_iam_policy_document.backup_assume.json
}

resource "aws_iam_role_policy_attachment" "backup_service" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restores" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_iam_role_policy_attachment" "backup_kms" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser"
}

# --- Backup Vault ---
resource "aws_backup_vault" "main" {
  name = "${var.project_name}-vault"

  tags = {
    Environment = var.environment
  }
}

# --- Backup Plan (Daily, 7-day retention) ---
resource "aws_backup_plan" "daily" {
  name = "${var.project_name}-daily-backup"

  rule {
    rule_name         = "DailyRule"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(30 17 * * ? *)" # 00:30 Asia/Saigon (UTC+7) = 17:30 UTC

    lifecycle {
      delete_after = 7
    }
  }

  tags = {
    Environment = var.environment
  }
}

# --- Resource Assignment ---
resource "aws_backup_selection" "resources" {
  name         = "${var.project_name}-resources"
  iam_role_arn = aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.daily.id

  # Sử dụng Tag-based selection: tất cả resource có tag Backup=true sẽ được backup
  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "true"
  }
}

# ─────────────────────────────────────────────────────────
# KMS Customer Managed Key (CMK)
# ─────────────────────────────────────────────────────────
# Shared KMS key for encrypting:
#   - S3 Frontend (static site)
#   - S3 AI Knowledge Base data
#   - S3 Centralized logs
#   - CloudWatch Logs (optional)
#
# NOT used for: RDS (keeps AWS-managed key)
# ─────────────────────────────────────────────────────────

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "main" {
  description             = "CMK for ${var.project_name} (${var.environment}) — S3, CloudWatch Logs"
  deletion_window_in_days = 14
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${var.project_name}-key-policy"
    Statement = [
      # ── Root account full access (required) ──
      {
        Sid    = "RootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # ── CloudFront can decrypt S3 objects ──
      {
        Sid    = "AllowCloudFrontDecrypt"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      # ── CloudWatch Logs can encrypt log data ──
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      },
      # ── S3 service can use key for SSE-KMS ──
      {
        Sid    = "AllowS3Encrypt"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-${var.environment}"
  target_key_id = aws_kms_key.main.key_id
}

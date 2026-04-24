# ─────────────────────────────────────────────────────────
# Kinesis Firehose — CloudWatch Logs → S3
# ─────────────────────────────────────────────────────────
# For each log group, creates:
#   1. Firehose delivery stream → writes to S3 with prefix
#   2. Subscription filter       → streams CW logs to Firehose
#
# Flow: CloudWatch Logs → Subscription Filter → Firehose → S3
# ─────────────────────────────────────────────────────────

# ── IAM Role for Firehose (write to S3 + use KMS) ──

resource "aws_iam_role" "firehose" {
  name = "${var.project_name}-firehose-logs-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "firehose" {
  name = "${var.project_name}-firehose-s3-${var.environment}"
  role = aws_iam_role.firehose.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Write"
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.logs.arn,
          "${aws_s3_bucket.logs.arn}/*"
        ]
      },
      {
        Sid    = "KMSEncrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_arn
      }
    ]
  })
}

# ── IAM Role for CloudWatch Logs (put records to Firehose) ──

resource "aws_iam_role" "cloudwatch_to_firehose" {
  name = "${var.project_name}-cwl-firehose-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudwatch_to_firehose" {
  name = "${var.project_name}-cwl-firehose-policy-${var.environment}"
  role = aws_iam_role.cloudwatch_to_firehose.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "FirehosePut"
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        Resource = [for k, v in var.log_exports : aws_kinesis_firehose_delivery_stream.logs[k].arn]
      }
    ]
  })
}

# ── Firehose Delivery Streams (1 per log group) ──

resource "aws_kinesis_firehose_delivery_stream" "logs" {
  for_each = var.log_exports

  name        = "${var.project_name}-${each.key}-${var.environment}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = aws_s3_bucket.logs.arn
    prefix     = "${each.value.s3_prefix}/"

    buffering_size     = 5   # MB — flush when buffer reaches 5MB
    buffering_interval = 300 # seconds — or flush every 5 minutes

    cloudwatch_logging_options {
      enabled = false
    }
  }
}

# ── CloudWatch Subscription Filters (1 per log group) ──

resource "aws_cloudwatch_log_subscription_filter" "to_firehose" {
  for_each = var.log_exports

  name            = "${var.project_name}-${each.key}-to-firehose"
  log_group_name  = each.value.log_group_name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.logs[each.key].arn
  role_arn        = aws_iam_role.cloudwatch_to_firehose.arn
}

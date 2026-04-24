# ─────────────────────────────────────────────────────────
# BedrockChat Module
# ─────────────────────────────────────────────────────────
# Creates:
#   1. Lambda function   – calls Bedrock KB Retrieve + Converse API
#   2. IAM role          – Lambda execution role with Bedrock permissions
#   3. API Gateway       – HTTP API (v2) with CORS for frontend
#   4. CloudWatch Logs   – Lambda log group + API Gateway access log
# ─────────────────────────────────────────────────────────

data "aws_caller_identity" "current" {}

# ─────────────────────────────────────────────────────────
# 1. Package Lambda code
# ─────────────────────────────────────────────────────────

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/index.py"
  output_path = "${path.module}/lambda/lambda.zip"
}

# ─────────────────────────────────────────────────────────
# 2. IAM Role for Lambda
# ─────────────────────────────────────────────────────────
#
# Trust policy  : lambda.amazonaws.com
# Inline policy : 3 statements
#
# ┌─────────────────────────┬───────────────────────────────────────────────────┐
# │ Policy Statement        │ Purpose                                           │
# ├─────────────────────────┼───────────────────────────────────────────────────┤
# │ bedrock:Retrieve        │ Query Knowledge Base for relevant documents       │
# │ bedrock:InvokeModel     │ Call model via Converse API to generate answer    │
# │ logs:CreateLogGroup     │ Create CloudWatch log group                       │
# │ logs:CreateLogStream    │ Create log stream inside group                    │
# │ logs:PutLogEvents       │ Write Lambda execution logs                       │
# └─────────────────────────┴───────────────────────────────────────────────────┘

resource "aws_iam_role" "lambda_chat" {
  name = "${var.project_name}-bedrock-chat-lambda-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_chat" {
  name = "${var.project_name}-bedrock-chat-policy-${var.environment}"
  role = aws_iam_role.lambda_chat.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BedrockKBRetrieve"
        Effect = "Allow"
        Action = [
          "bedrock:Retrieve"
        ]
        Resource = "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:knowledge-base/${var.knowledge_base_id}"
      },
      {
        Sid    = "BedrockModelInvoke"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = [
          "arn:aws:bedrock:${var.aws_region}::foundation-model/*",
          "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:inference-profile/*",
          "arn:aws:bedrock:us-*::foundation-model/*"
        ]
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

# ─────────────────────────────────────────────────────────
# 3. CloudWatch Log Groups
# ─────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "lambda_chat" {
  name              = "/aws/lambda/${var.project_name}-bedrock-chat-${var.environment}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/apigateway/${var.project_name}-chat-api-${var.environment}"
  retention_in_days = 14
}

# ─────────────────────────────────────────────────────────
# 4. Lambda Function
# ─────────────────────────────────────────────────────────

resource "aws_lambda_function" "chat" {
  function_name    = "${var.project_name}-bedrock-chat-${var.environment}"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  handler          = "index.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_chat.arn
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory

  environment {
    variables = {
      KNOWLEDGE_BASE_ID = var.knowledge_base_id
      MODEL_ID          = var.model_id
      ALLOWED_ORIGIN    = var.allowed_origin
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_chat,
    aws_iam_role_policy.lambda_chat
  ]
}

# ─────────────────────────────────────────────────────────
# 5. API Gateway — HTTP API (v2)
# ─────────────────────────────────────────────────────────
# HTTP API is faster (~60%), cheaper ($1/M vs $3.5/M),
# and has built-in CORS support.

resource "aws_apigatewayv2_api" "chat" {
  name          = "${var.project_name}-chat-api-${var.environment}"
  protocol_type = "HTTP"
  description   = "AI Chat HTTP API — ${var.project_name} (${var.environment})"

  cors_configuration {
    allow_origins = [var.allowed_origin]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
    max_age       = 86400
  }
}

# ── Lambda Integration ──

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.chat.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.chat.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# ── Route: POST /chat ──

resource "aws_apigatewayv2_route" "chat_post" {
  api_id    = aws_apigatewayv2_api.chat.id
  route_key = "POST /chat"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# ── Stage with access logging ──

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.chat.id
  name        = "prod"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      httpMethod     = "$context.httpMethod"
      path           = "$context.path"
      status         = "$context.status"
      responseLength = "$context.responseLength"
      latency        = "$context.integrationLatency"
      requestTime    = "$context.requestTime"
    })
  }
}

# ── Lambda Permission for API Gateway ──

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowHTTPAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chat.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.chat.execution_arn}/*/*"
}

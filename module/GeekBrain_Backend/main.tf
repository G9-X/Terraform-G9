# ═══════════════════════════════════════
# GeekBrain Backend — Bedrock Agent + Lambda + API Gateway
# Adapted from W4 backend module
# ═══════════════════════════════════════

# ═══════════════════════════════════════
# Main Lambda (API Gateway → invoke Agent)
# ═══════════════════════════════════════

resource "aws_iam_role" "lambda" {
  name = "${var.project}-geekbrain-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_bedrock" {
  name = "${var.project}-lambda-bedrock"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["bedrock:InvokeAgent"]
        Resource = "arn:aws:bedrock:${var.region}:${var.account_id}:agent-alias/${aws_bedrockagent_agent.main.agent_id}/*"
      }
    ]
  })
}

data "archive_file" "lambda_main" {
  type        = "zip"
  source_file = "${path.root}/../lambda/geekbrain/lambda_function.py"
  output_path = "${path.module}/.build/lambda_main.zip"
}

resource "aws_lambda_function" "chat" {
  function_name    = "${var.project}-geekbrain-chat"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.12"
  timeout          = 120
  memory_size      = 256
  filename         = data.archive_file.lambda_main.output_path
  source_code_hash = data.archive_file.lambda_main.output_base64sha256

  environment {
    variables = {
      AGENT_ID          = aws_bedrockagent_agent.main.agent_id
      AGENT_ALIAS_ID    = aws_bedrockagent_agent_alias.prod.agent_alias_id
      AWS_REGION_NAME   = var.region
      KNOWLEDGE_BASE_ID = var.knowledge_base_id
      RETRIEVAL_K       = tostring(var.retrieval_k)
    }
  }

  depends_on = [aws_bedrockagent_agent_alias.prod]
  tags       = var.tags
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chat.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# ═══════════════════════════════════════
# Action Group Lambda (tool execution — runs in VPC)
# ═══════════════════════════════════════

resource "aws_iam_role" "action_group_lambda" {
  name = "${var.project}-action-group-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "action_group_lambda_logs" {
  role       = aws_iam_role.action_group_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "null_resource" "action_group_build" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command     = "python build.py"
    working_dir = "${path.root}/../lambda/geekbrain"
  }
}

data "archive_file" "lambda_action_group" {
  type        = "zip"
  source_dir  = "${path.root}/../lambda/geekbrain/.build"
  output_path = "${path.module}/.build/lambda_action_group.zip"
  depends_on  = [null_resource.action_group_build]
}

resource "aws_lambda_function" "action_group" {
  function_name    = "${var.project}-action-group"
  role             = aws_iam_role.action_group_lambda.arn
  handler          = "action_group_function.handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 256
  filename         = data.archive_file.lambda_action_group.output_path
  source_code_hash = data.archive_file.lambda_action_group.output_base64sha256
  tags             = var.tags

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  environment {
    variables = {
      DB_HOST            = var.db_host
      DB_NAME            = var.db_name
      DB_USER            = var.db_user
      DB_PASSWORD        = var.db_password
    }
  }
}

resource "aws_lambda_permission" "bedrock_action_group" {
  statement_id  = "AllowBedrockInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.action_group.function_name
  principal     = "bedrock.amazonaws.com"
  source_arn    = "arn:aws:bedrock:${var.region}:${var.account_id}:agent/${aws_bedrockagent_agent.main.agent_id}"
}

# ═══════════════════════════════════════
# Bedrock Agent
# ═══════════════════════════════════════

resource "aws_iam_role" "bedrock_agent" {
  name = "${var.project}-bedrock-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "bedrock.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = { "aws:SourceAccount" = var.account_id }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "bedrock_agent_model" {
  name = "${var.project}-agent-model-access"
  role = aws_iam_role.bedrock_agent.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream",
          "bedrock:GetFoundationModel",
          "bedrock:GetInferenceProfile",
          "bedrock:ListInferenceProfiles"
        ]
        Resource = [
          "arn:aws:bedrock:${var.region}::foundation-model/${var.llm_model_id}",
          "arn:aws:bedrock:${var.region}::foundation-model/*",
          "arn:aws:bedrock:*:${var.account_id}:inference-profile/*",
          "arn:aws:bedrock:*::inference-profile/*",
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["bedrock:Retrieve"]
        Resource = "arn:aws:bedrock:${var.region}:${var.account_id}:knowledge-base/${var.knowledge_base_id}"
      }
    ]
  })
}

resource "aws_bedrockagent_agent" "main" {
  agent_name                  = "${var.project}-agent"
  agent_resource_role_arn     = aws_iam_role.bedrock_agent.arn
  foundation_model            = var.llm_model_id
  idle_session_ttl_in_seconds = 1800

  instruction = <<-EOT
You are GeekBrain AI Assistant. You answer questions about GeekBrain — a fintech startup in Ho Chi Minh City running six production services: PaymentGW, AuthSvc, OrderSvc, FraudDetector, NotificationSvc, ReportingSvc.

RULES:
1. Answer using ONLY the knowledge base and tool results. Do NOT guess or make up information.
2. Always cite the source document name(s) in your answer using [source: filename.md].
3. When documents conflict, prefer the most recent version and status="current" over "archived". State the conflict explicitly.
4. For questions about specific NUMBERS (costs, SLA targets, daily metrics, historical data), you MUST use the query_database tool. Never guess numbers.
5. For questions about CURRENT/LIVE status or real-time performance, use get_service_status or get_service_metrics tools.
6. For factual questions about people, policies, processes, architecture — answer from the knowledge base directly.
7. If you cannot find the answer, say so honestly. Do not hallucinate.
8. Be EXTREMELY concise. Keep your answers under 100 words to prevent system timeouts. Do not over-explain.
9. When comparing services, use the compare_services tool for accurate data.
10. To save time, if compare_services gives you the metric value, DO NOT also call get_service_metrics.
11. EFFICIENCY: If the knowledge base already returned relevant chunks that answer the question, respond IMMEDIATELY. Do NOT re-query the knowledge base for the same question or similar information.
12. For simple factual questions (who, what, where), ONE knowledge base lookup is enough. Do NOT do multiple lookups.
13. NEVER call the same tool twice with the same or similar parameters. If you already have the data, use it.

DATABASE SCHEMA (for query_database tool):
- Categories: Id, Name, Description, DisplayOrder, Slug, ParentId
- OrderItems: Id, OrderId, ProductId, ProductVariantId, ProductName, VariantName, Sku, Quantity, UnitPrice, SubTotal, Tax, StoreId
- Orders: Id, OrderNumber, Status, PaymentStatus, SubTotal, Tax, ShippingCost, TotalAmount, CreatedAt, CompletedAt
- ProductCategories: ProductId, CategoryId
- ProductVariants: Id, ProductId, Sku, Color, Size, Price, StockQuantity
- Products: Id, Name, Slug, Description, BasePrice, ViewCount, SalesCount, IsActive, CreatedAt, StoreId
- Reviews: Id, Rating, Comment, CreatedAt, ProductId, StoreId
- Stores: Id, Name, Slug, Status, CreatedAt
  EOT

  tags = var.tags

  # Model is managed via console — DeepSeek V3.2 causes API errors via Terraform
  lifecycle {
    ignore_changes = [foundation_model]
  }
}

resource "aws_bedrockagent_agent_knowledge_base_association" "main" {
  agent_id             = aws_bedrockagent_agent.main.agent_id
  agent_version        = "DRAFT"
  knowledge_base_id    = var.knowledge_base_id
  description          = "GeekBrain knowledge base with 36 documents: company policies, team info, service architecture, incident postmortems, runbooks, API references, and strategic planning documents."
  knowledge_base_state = "ENABLED"
}

resource "aws_bedrockagent_agent_action_group" "tools" {
  agent_id                   = aws_bedrockagent_agent.main.agent_id
  agent_version              = "DRAFT"
  action_group_name          = "${var.project}-tools"
  action_group_state         = "ENABLED"
  skip_resource_in_use_check = true

  action_group_executor {
    lambda = aws_lambda_function.action_group.arn
  }

  function_schema {
    member_functions {
      functions {
        name        = "query_database"
        description = <<-DESC
          Execute a SQL SELECT query on the RDS MySQL database containing Merxly e-commerce data.
          USE THIS to query users, products, orders, reviews, etc.
        DESC
        parameters {
          map_block_key = "sql_query"
          type          = "string"
          description   = "SQL SELECT query to execute. Only SELECT queries allowed."
          required      = true
        }
      }
    }
  }
}

# Prepare agent after all components are configured
resource "null_resource" "prepare_agent" {
  triggers = {
    agent_id        = aws_bedrockagent_agent.main.agent_id
    action_group_id = aws_bedrockagent_agent_action_group.tools.action_group_id
    kb_association  = aws_bedrockagent_agent_knowledge_base_association.main.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Preparing Bedrock Agent..."
      aws bedrock-agent prepare-agent --agent-id ${aws_bedrockagent_agent.main.agent_id} --region ${var.region}
      echo "Waiting 30s for agent preparation..."
      sleep 30
      echo "Agent prepared."
    EOT
  }
}

resource "aws_bedrockagent_agent_alias" "prod" {
  agent_alias_name = "prod"
  agent_id         = aws_bedrockagent_agent.main.agent_id
  tags             = var.tags

  depends_on = [null_resource.prepare_agent]
}

# ═══════════════════════════════════════
# API Gateway — Chat endpoint
# ═══════════════════════════════════════

resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project}-chat-api"
  description = "GeekBrain AI Chat API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

resource "aws_api_gateway_resource" "chat" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "chat"
}

resource "aws_api_gateway_method" "chat_post" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.chat.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "chat_post" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.chat.id
  http_method             = aws_api_gateway_method.chat_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.chat.invoke_arn
}

resource "aws_api_gateway_method" "chat_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.chat.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "chat_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.chat.id
  http_method = aws_api_gateway_method.chat_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "chat_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.chat.id
  http_method = aws_api_gateway_method.chat_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "chat_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.chat.id
  http_method = aws_api_gateway_method.chat_options.http_method
  status_code = aws_api_gateway_method_response.chat_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.chat.id,
      aws_api_gateway_method.chat_post.id,
      aws_api_gateway_integration.chat_post.id,
      aws_api_gateway_method.chat_options.id,
      aws_api_gateway_integration.chat_options.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "prod"
  tags          = var.tags
}

# ═══════════════════════════════════════
# API Gateway — Usage Plan + API Key (W5 MH4: Throttling + Auth)
# ═══════════════════════════════════════

resource "aws_api_gateway_usage_plan" "chat" {
  name = "${var.project}-chat-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_stage.prod.stage_name
  }

  throttle_settings {
    rate_limit  = var.api_throttle_rate_limit
    burst_limit = var.api_throttle_burst_limit
  }

  quota_settings {
    limit  = var.api_quota_limit
    period = "DAY"
  }

  tags = var.tags
}

resource "aws_api_gateway_api_key" "chat" {
  name    = "${var.project}-chat-api-key"
  enabled = true
  tags    = var.tags
}

resource "aws_api_gateway_usage_plan_key" "chat" {
  key_id        = aws_api_gateway_api_key.chat.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.chat.id
}

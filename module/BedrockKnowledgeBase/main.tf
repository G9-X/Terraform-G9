# ─────────────────────────────────────────────────────────
# Bedrock Knowledge Base Module
# ─────────────────────────────────────────────────────────
# Creates:
#   1. S3 bucket            – document storage (data source)
#   2. OpenSearch Serverless – vector store (collection + policies)
#   3. IAM role              – Bedrock service role
#   4. Bedrock Knowledge Base
#   5. Bedrock Data Source   – S3 → KB
# ─────────────────────────────────────────────────────────

data "aws_caller_identity" "current" {}

locals {
  collection_name = "${var.project_name}-${var.collection_name_suffix}-${var.environment}"

  # All principals granted data-level access inside the AOSS collection.
  # Always includes the Bedrock service role; callers (e.g. your own IAM
  # user/role) can be added via var.additional_access_policy_principals
  # so they can run the one-time index-creation script.
  access_policy_principals = concat(
    [aws_iam_role.bedrock_kb.arn],
    var.additional_access_policy_principals
  )
}

# ─────────────────────────────────────────────────────────
# 1. S3 Bucket — KB data source (documents to ingest)
# ─────────────────────────────────────────────────────────

resource "aws_s3_bucket" "kb_data" {
  bucket = "${var.project_name}-kb-data-${var.environment}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "kb_data" {
  bucket = aws_s3_bucket.kb_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "kb_data" {
  bucket = aws_s3_bucket.kb_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ─────────────────────────────────────────────────────────
# 2. IAM Role for Bedrock Knowledge Base
# ─────────────────────────────────────────────────────────
#
# Trust policy  : bedrock.amazonaws.com
# Inline policy : 4 statements (see below)
#
# ┌──────────────────────────┬──────────────────────────────────────────────────────────────┐
# │ Policy Statement         │ Purpose                                                      │
# ├──────────────────────────┼──────────────────────────────────────────────────────────────┤
# │ s3:GetObject             │ Read documents from KB data bucket                           │
# │ s3:ListBucket            │ List objects in KB data bucket                                │
# │ bedrock:InvokeModel      │ Call Titan Embed v2 to create embeddings                     │
# │ aoss:APIAccessAll        │ Read/write vectors to OpenSearch Serverless collection       │
# └──────────────────────────┴──────────────────────────────────────────────────────────────┘

data "aws_iam_policy_document" "bedrock_kb_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "bedrock_kb" {
  name               = "${var.project_name}-bedrock-kb-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.bedrock_kb_assume.json
}

data "aws_iam_policy_document" "bedrock_kb_permissions" {

  # ── S3: read documents from data-source bucket ──
  statement {
    sid       = "S3DataSourceRead"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.kb_data.arn}/*"]
  }

  statement {
    sid       = "S3DataSourceList"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.kb_data.arn]
  }

  # ── Bedrock: invoke embedding model (Titan Embed Text v2) ──
  statement {
    sid       = "BedrockModelInvoke"
    actions   = ["bedrock:InvokeModel"]
    resources = ["arn:aws:bedrock:${var.aws_region}::foundation-model/${var.embedding_model_id}"]
  }

  # ── OpenSearch Serverless: read/write vectors ──
  statement {
    sid       = "OpenSearchServerlessAccess"
    actions   = ["aoss:APIAccessAll"]
    resources = [aws_opensearchserverless_collection.kb.arn]
  }
}

resource "aws_iam_role_policy" "bedrock_kb" {
  name   = "${var.project_name}-bedrock-kb-policy-${var.environment}"
  role   = aws_iam_role.bedrock_kb.id
  policy = data.aws_iam_policy_document.bedrock_kb_permissions.json
}

# ─────────────────────────────────────────────────────────
# 3. OpenSearch Serverless — Vector Store
# ─────────────────────────────────────────────────────────

# 3a. Encryption policy — AWS-owned key (no extra KMS cost)
resource "aws_opensearchserverless_security_policy" "encryption" {
  name = "${local.collection_name}-enc"
  type = "encryption"

  policy = jsonencode({
    Rules = [
      {
        ResourceType = "collection"
        Resource     = ["collection/${local.collection_name}"]
      }
    ]
    AWSOwnedKey = true
  })
}

# 3b. Network policy — public access (required for Bedrock service)
resource "aws_opensearchserverless_security_policy" "network" {
  name = "${local.collection_name}-net"
  type = "network"

  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource     = ["collection/${local.collection_name}"]
        },
        {
          ResourceType = "dashboard"
          Resource     = ["collection/${local.collection_name}"]
        }
      ]
      AllowFromPublic = true
    }
  ])
}

# 3c. Data access policy — Bedrock role + optional callers
resource "aws_opensearchserverless_access_policy" "kb" {
  name = "${local.collection_name}-access"
  type = "data"

  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource     = ["collection/${local.collection_name}"]
          Permission = [
            "aoss:CreateCollectionItems",
            "aoss:DeleteCollectionItems",
            "aoss:UpdateCollectionItems",
            "aoss:DescribeCollectionItems"
          ]
        },
        {
          ResourceType = "index"
          Resource     = ["index/${local.collection_name}/*"]
          Permission = [
            "aoss:CreateIndex",
            "aoss:DeleteIndex",
            "aoss:UpdateIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:WriteDocument"
          ]
        }
      ]
      Principal = local.access_policy_principals
    }
  ])
}

# 3d. Collection (VECTORSEARCH) — must wait for all policies
resource "aws_opensearchserverless_collection" "kb" {
  name = local.collection_name
  type = "VECTORSEARCH"

  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network,
    aws_opensearchserverless_access_policy.kb
  ]
}

# ─────────────────────────────────────────────────────────
# 4. Bedrock Knowledge Base
# ─────────────────────────────────────────────────────────
#
# IMPORTANT: The vector index inside the AOSS collection must
# be created BEFORE this resource can function.  Terraform
# cannot create AOSS indexes natively — run the helper script
# `create_opensearch_index.py` once after the first apply.

resource "aws_bedrockagent_knowledge_base" "main" {
  name        = "${var.project_name}-kb-${var.environment}"
  description = "Knowledge Base for ${var.project_name} (${var.environment})"
  role_arn    = aws_iam_role.bedrock_kb.arn

  knowledge_base_configuration {
    type = "VECTOR"

    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.embedding_model_id}"
    }
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"

    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.kb.arn
      vector_index_name = var.vector_index_name

      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }

  depends_on = [
    aws_iam_role_policy.bedrock_kb,
    aws_opensearchserverless_collection.kb
  ]
}

# ─────────────────────────────────────────────────────────
# 5. Bedrock Data Source — S3 (default parser, whole bucket)
# ─────────────────────────────────────────────────────────

resource "aws_bedrockagent_data_source" "s3" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.main.id
  name              = "${var.project_name}-s3-datasource-${var.environment}"

  data_source_configuration {
    type = "S3"

    s3_configuration {
      bucket_arn = aws_s3_bucket.kb_data.arn
    }
  }
}

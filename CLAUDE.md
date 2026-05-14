# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Terraform infrastructure for the **XBrain** platform — a .NET e-commerce backend with a RAG-based AI chatbot (GeekBrain). Deploys to AWS `us-west-2` using GitHub Actions with OIDC authentication.

## Commands

```bash
# Format all .tf files
terraform fmt -recursive

# Validate configuration (run from environment directory)
cd us-dev && terraform init -backend-config="region=us-west-2" && terraform validate
cd us-dev-static && terraform init -backend-config="region=us-west-2" && terraform validate

# Plan changes
cd us-dev && terraform plan -var-file=terraform.tfvars

# Apply (local — CI handles production applies on main push)
cd us-dev && terraform apply -var-file=terraform.tfvars
```

## Architecture

Two independent stacks share a common module library:

```
us-dev/          → Backend stack (VPC, ALB, ECS, RDS MySQL, ECR, GeekBrain AI)
us-dev-static/   → Frontend stack (S3 + CloudFront + OAC, Route53)
module/          → Reusable modules consumed by both stacks
```

### Backend Stack (`us-dev/`) — Module Dependency Graph

```
Networking (VPC, subnets, NAT)
    ↓
Security (SGs: ALB, backend, RDS, Lambda)
    ↓
┌───────────┬──────────────┬──────────────────┐
ALB         ECR            Database_MySQL [optional]
    ↓         ↓                    ↓
ECS_Backend (Fargate tasks, Secrets Manager, CloudWatch)
    ↓
GitHubActionsOIDC (deploy role)
    ↓
GeekBrain_AI_Engine (Bedrock KB + OpenSearch Serverless + S3 docs)
    ↓
GeekBrain_Backend (Bedrock Agent + Lambda + API Gateway)
```

### Feature Flags (variables controlling optional resources)

| Variable | Effect |
|----------|--------|
| `enable_rds` | Provisions RDS MySQL instance and subnet group |
| `enable_github_actions_oidc` | Creates OIDC provider + deploy IAM role |
| `enable_geekbrain` | Provisions Bedrock KB, OpenSearch, Lambda, API Gateway |

### State Backend

- **Bucket:** `xbrain-terraform-state` (auto-bootstrapped by CI if missing)
- **Lock:** DynamoDB table `terraform-state-lock`
- **State keys:** `us-dev/terraform.tfstate`, `us-dev-static/terraform.tfstate`
- Region passed via `-backend-config="region=..."` (not hardcoded in provider.tf)

### GeekBrain AI Architecture

RAG chatbot using AWS Bedrock Agent:
1. API Gateway → `lambda/geekbrain/lambda_function.py` → invokes Bedrock Agent
2. Bedrock Agent orchestrates: Knowledge Base retrieval (OpenSearch Serverless) + Action Group tools
3. Action Group Lambda (`lambda/geekbrain/action_group_function.py`) handles DB queries and Monitoring API calls
4. Knowledge base documents stored in S3, sourced from `data_package/knowledge_base/`

### CI/CD

- **terraform-ci.yml** — On push to main: bootstrap backend → init → fmt check → validate → plan → apply (matrix: `[us-dev, us-dev-static]`)
- **terraform-destroy.yml** — Manual workflow_dispatch with confirmation guard
- Auth: GitHub OIDC → `TF_AWS_ROLE_ARN` secret
- Secrets passed as `TF_VAR_*` env vars (never in state or tfvars committed to git)

## Module Conventions

- Each module: `main.tf` (resources), `variables.tf` (inputs), `outputs.tf` (outputs)
- Module directory names: PascalCase (`GeekBrain_AI_Engine`, `Database_MySQL`)
- Resource naming pattern: `${var.project_name}-<resource>-${var.environment}`
- All resources auto-tagged via provider `default_tags` block
- Conditional modules use `count = var.enable_x ? 1 : 0` pattern

## Sensitive Variables

These must never be hardcoded — pass via `TF_VAR_*` env or `-var`:
`db_password`, `jwt_secret_key`, `cloudinary_api_key`, `cloudinary_api_secret`, `stripe_secret_key`, `stripe_publishable_key`, `stripe_webhook_secret`

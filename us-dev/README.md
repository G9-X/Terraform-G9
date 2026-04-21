# us-dev

Environment stack for backend API, ECR, optional RDS MySQL, and GitHub Actions OIDC deploy role.

## What this environment creates
- VPC with public, private-app, and private-data subnets across 2 AZs
- NAT Gateways (one per AZ) and route tables
- Security groups for ALB, backend ECS tasks, and RDS MySQL
- Public ALB for backend API ingress
- ECR repository for backend container images
- ECS service on EC2 capacity provider for backend
- Optional RDS MySQL instance (`enable_rds`)
- Optional IAM OIDC role for GitHub Actions (`enable_github_actions_oidc`)

## Deploy steps
1. Copy `terraform.tfvars.example` to `terraform.tfvars`.
2. Set database credentials and network ranges.
3. Run:
   - `terraform init`
   - `terraform plan`
   - `terraform apply`
4. Put output `github_actions_role_arn` into GitHub variable `AWS_DEPLOY_ROLE_ARN`.
5. Trigger deploy workflow to build image, push ECR, migrate DB, and update ECS.
6. Set `backend_desired_count` to at least `1` and apply again if needed.

## Automatic backend deploy flow (GitHub Actions + OIDC)

When `enable_github_actions_oidc = true`:

1. Terraform creates IAM OIDC provider (optional) and IAM role for GitHub Actions.
2. You set role ARN into GitHub repository Variables/Secrets.
3. Deploy workflow uses `aws-actions/configure-aws-credentials` with OIDC.
4. GitHub Actions builds Docker image, pushes to ECR, runs EF migration, then updates ECS.

Important: in this mode, CI/CD does build image directly in GitHub Actions, then push to ECR. You do not need to pull code to another server to build image.

### Outputs to use in workflow setup

- `github_actions_role_arn`
- `ecs_cluster_name`
- `ecs_service_name`
- `ecs_capacity_provider_name`
- `ecs_autoscaling_group_name`
- `ecr_repository_url`
- `rds_endpoint`

Detailed runbook:
- See `DEPLOY_AND_DATA_SYNC.md` in this folder.

## RDS MySQL specifics
- Engine default: `mysql`.
- Port: `3306`.
- Storage encryption: enabled.
- DB is private (`publicly_accessible = false`) and reachable only from backend SG.

## Important
- Use a strong password and avoid weak/default credentials.
- For production, set `skip_final_snapshot = false` and add backup/monitoring policies.

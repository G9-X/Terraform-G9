# terraform_xbrain

Terraform workspace with structure similar to Terraform_IaC.

## Structure
- `us-dev-static/`: static frontend stack (S3 + CloudFront + OAC)
- `us-dev/`: backend + ECR + optional RDS MySQL environment stack
- `module/`: reusable modules (Networking, Security, ALB, ECR, ECS_Backend, Database_MySQL, CICD)

## Backend + MySQL deployment flow
1. Go to `us-dev/`.
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and set real values (including ECS EC2 capacity sizing).
3. Run `terraform init`.
4. Run `terraform apply`.
5. Get output `github_actions_role_arn` and set it to GitHub Actions variable (for example `AWS_DEPLOY_ROLE_ARN`).
6. Trigger backend deploy workflow to build image, push ECR, migrate DB, and update ECS.
7. Set `backend_desired_count` to 1 (or more) and `terraform apply` again if needed.

## Do you need RDS immediately?
- No, not required for first API bootstrap.
- Use `enable_rds = false` if backend does not need relational data yet.
- Enable RDS when your backend needs persistent SQL data.

## How to deploy RDS MySQL on AWS with this stack
- Set `enable_rds = true` in `us-dev/terraform.tfvars`.
- Provide `db_username` and strong `db_password`.
- Keep private data subnets and SG rules as-is (MySQL port 3306 only from backend SG).
- Run `terraform apply`.
- Use output `rds_endpoint` and `rds_port` in backend connection string.

Connection string format for .NET (Pomelo MySQL):
`Server=<rds_endpoint>;Port=3306;Database=<db_name>;User=<db_username>;Password=<db_password>;SslMode=Preferred;`

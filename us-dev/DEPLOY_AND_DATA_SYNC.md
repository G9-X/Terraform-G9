# Backend Deploy to ECS + Import Data to RDS (MySQL)

This runbook covers the flow after enabling GitHub Actions OIDC role in `terraform_xbrain/us-dev`.

## 1) One-time setup

1. Apply Terraform in `terraform_xbrain/us-dev` with:
  - `enable_rds = true`
  - `enable_github_actions_oidc = true`
  - valid GitHub repo owner/name/branch variables
2. Verify outputs:
  - `github_actions_role_arn`
   - `ecr_repository_url`
   - `ecs_cluster_name`
   - `ecs_service_name`
  - `ecs_capacity_provider_name`
  - `ecs_autoscaling_group_name`
   - `rds_endpoint`
3. In GitHub repository variables/secrets, set:
  - `AWS_DEPLOY_ROLE_ARN` (or `WORKSHOP_AWS_ROLE_ARN`) = `github_actions_role_arn`

## 2) Push code and auto deploy backend ECS

After setup, every push to configured branch triggers GitHub workflow:

1. Workflow assumes AWS role through OIDC.
2. Workflow builds backend Docker image.
3. Workflow pushes image to ECR.
4. Workflow runs EF migration to MySQL (`dotnet ef database update`).
5. Workflow registers new ECS task definition revision and updates ECS service.

You do not need to pull code to another machine for image build in this flow.

### Important checks

- Ensure backend folder is either `merxly_backend` or `be`.
- Ensure task definition has container name matching `backend_container_name` (default `backend`).
- Ensure runner can reach private RDS (self-hosted in VPC, VPN, or tunnel).

## 3) Import data from primary DB to workshop RDS

Schema is handled by migration. Data should be imported separately.

### Export from primary MySQL

```bash
mysqldump \
  --single-transaction \
  --routines --triggers \
  -h <PRIMARY_HOST> -P 3306 -u <PRIMARY_USER> -p \
  <DB_NAME> > primary_dump.sql
```

### Import to workshop RDS MySQL

```bash
mysql \
  -h <WORKSHOP_RDS_ENDPOINT> -P 3306 -u <WORKSHOP_USER> -p \
  <DB_NAME> < primary_dump.sql
```

### Verify basic integrity

```bash
mysql -h <WORKSHOP_RDS_ENDPOINT> -P 3306 -u <WORKSHOP_USER> -p -e "SHOW TABLES;" <DB_NAME>
mysql -h <WORKSHOP_RDS_ENDPOINT> -P 3306 -u <WORKSHOP_USER> -p -e "SELECT COUNT(*) FROM __EFMigrationsHistory;" <DB_NAME>
```

## 4) Recommended weekly workshop flow

1. Recreate infra (Terraform apply).
2. Trigger deploy workflow once to apply latest schema + deploy backend image.
3. Import sanitized data dump from primary DB.
4. Run smoke tests against API endpoints.

## 5) Failure handling

- Migration fails:
  - check `BACKEND_DB_CONNECTION_STRING`
  - check network route and SG (GitHub runner to RDS 3306)
- ECS deploy fails:
  - check task definition container name
  - check image pushed to ECR and tag exists
  - check ECS service events

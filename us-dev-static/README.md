# us-dev-static

Static frontend stack for public S3 website hosting.

## What this stack creates
- Public S3 bucket for static files
- S3 website endpoint (index and error document)
- Public-read bucket policy for website assets
- Optional Route53 CNAME for custom subdomain

## Notes
- This stack intentionally does not create CloudFront.
- Use a subdomain (for example `app.example.com`) when setting `domain_name`.
- If your frontend calls backend APIs, point `VITE_API_BASE_URL` directly to ALB/API domain.

## Quick start
1. Copy `terraform.tfvars.example` to `terraform.tfvars` and adjust values.
2. Run:
   - `terraform init`
   - `terraform plan`
   - `terraform apply`
3. Upload site files:
   - `aws s3 sync ./dist s3://<static_bucket_name> --delete`

# Tài Liệu Resource Policy Toàn Bộ (us-dev + us-dev-static)

## 1. Mục tiêu

Tài liệu này tổng hợp toàn bộ **resource policy liên quan đến IAM/S3/Secrets Manager** trong hạ tầng hiện tại để phục vụ đối soát, review bảo mật và nộp minh chứng.

Phạm vi:
- Stack backend: `terraform_xbrain/us-dev`
- Stack frontend static: `terraform_xbrain/us-dev-static`

## 2. Danh sách định danh đã triển khai (evidence từ state)

### 2.1 IAM Roles (us-dev)
- `arn:aws:iam::891612555776:role/xbrain-ecs-instance-us-dev`
- `arn:aws:iam::891612555776:role/xbrain-ecs-exec-us-dev`
- `arn:aws:iam::891612555776:role/xbrain-ecs-task-us-dev`
- `arn:aws:iam::891612555776:role/xbrain-gha-oidc-us-dev`

### 2.2 S3 bucket static (us-dev-static)
- Bucket: `xbrain-static-i46zjt`
- ARN: `arn:aws:s3:::xbrain-static-i46zjt`
- Website endpoint: `xbrain-static-i46zjt.s3-website-us-east-1.amazonaws.com`

## 3. IAM Trust Policy (Assume Role Policy)

## 3.1 ECS Instance Role
Role: `xbrain-ecs-instance-us-dev`

Trust policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
}
```

Ý nghĩa:
- Chỉ EC2 service được assume role này.
- Dùng cho ECS container instance (EC2) qua Instance Profile.

## 3.2 ECS Task Execution Role
Role: `xbrain-ecs-exec-us-dev`

Trust policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      }
    }
  ]
}
```

Ý nghĩa:
- Chỉ ECS tasks được assume.
- Dùng cho execution runtime (pull image/logging).

## 3.3 ECS Task Role
Role: `xbrain-ecs-task-us-dev`

Trust policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      }
    }
  ]
}
```

Ý nghĩa:
- Chỉ ECS tasks được assume.
- Là identity cho application container.

## 3.4 GitHub Actions OIDC Role
Role: `xbrain-gha-oidc-us-dev`

Trust policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Principal": {
        "Federated": "arn:aws:iam::891612555776:oidc-provider/token.actions.githubusercontent.com"
      },
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:G9-X/Merxly-XB9:*"
        }
      }
    }
  ]
}
```

Ý nghĩa:
- Chỉ workflow GitHub Actions thuộc repo `G9-X/Merxly-XB9` mới được assume role.
- Không dùng access key tĩnh cho pipeline backend.

## 4. IAM Permission Policy và Policy Attachment

## 4.1 Role `xbrain-ecs-instance-us-dev`
Managed policies gắn vào role:
- `arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role`
- `arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore`

Ý nghĩa quyền chính:
- Quyền ECS agent trên EC2.
- Quyền SSM managed instance để remote/session.

## 4.2 Role `xbrain-ecs-exec-us-dev`
Managed policy gắn vào role:
- `arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy`

Inline policy gắn vào role:
- Cho phép `secretsmanager:GetSecretValue` trên secret DB connection của backend.

Ý nghĩa quyền chính:
- Pull image từ ECR.
- Ghi log CloudWatch Logs (theo scope managed policy của AWS).
- Đọc connection string từ AWS Secrets Manager để inject vào container khi task khởi chạy.

## 4.3 Role `xbrain-ecs-task-us-dev`
Trạng thái hiện tại:
- Không có managed policy gắn thêm.
- Không có inline policy trong state.

Ý nghĩa:
- Task có IAM identity nhưng gần như không có quyền gọi AWS API bổ sung ngoài mặc định IAM context.

## 4.4 Inline Policy của role `xbrain-gha-oidc-us-dev`
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "ecr:GetAuthorizationToken",
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ecr:UploadLayerPart",
        "ecr:PutImage",
        "ecr:ListImages",
        "ecr:InitiateLayerUpload",
        "ecr:DescribeRepositories",
        "ecr:DescribeImages",
        "ecr:CompleteLayerUpload",
        "ecr:BatchCheckLayerAvailability"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:ecr:us-east-1:891612555776:repository/xbrain-backend-us-dev"
    },
    {
      "Action": [
        "ecs:UpdateService",
        "ecs:RegisterTaskDefinition",
        "ecs:ListTasks",
        "ecs:DescribeTasks",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeServices",
        "ecs:DescribeClusters"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": "iam:PassRole",
      "Effect": "Allow",
      "Resource": [
        "arn:aws:iam::891612555776:role/xbrain-ecs-task-us-dev",
        "arn:aws:iam::891612555776:role/xbrain-ecs-exec-us-dev"
      ]
    }
  ]
}
```

Ý nghĩa:
- Cho phép CI/CD backend build/push image và rollout ECS.
- `iam:PassRole` bị giới hạn vào đúng 2 role task/execution, không phải wildcard toàn account.

## 5. S3 Resource Policy (us-dev-static)

## 5.1 Bucket-level Public Access Block (đã áp dụng)
Cấu hình hiện tại trên bucket `xbrain-static-i46zjt`:
- `BlockPublicAcls = false`
- `IgnorePublicAcls = false`
- `BlockPublicPolicy = false`
- `RestrictPublicBuckets = false`

## 5.2 Bucket Policy public-read cho website (được định nghĩa trong Terraform)
Policy document được định nghĩa trong code:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::xbrain-static-i46zjt/*"
    }
  ]
}
```

Lưu ý trạng thái triển khai:
- Tại thời điểm trích state, chưa thấy resource `aws_s3_bucket_policy` trong `us-dev-static/terraform.tfstate`.
- Nghĩa là bucket policy public-read có thể chưa apply thành công ở lần chạy trước.

## 6. Secrets Manager Resource Policy / Access Policy (us-dev)

### 6.1 Secret backend DB connection
- Resource: `aws_secretsmanager_secret.backend_db_connection`
- Tên secret: `${project_name}/backend/${environment}/db-connection`
- Mục đích: lưu connection string backend thay cho plaintext trong ECS task definition.

### 6.2 IAM access policy tới secret
- Principal thực thi: role `xbrain-ecs-exec-us-dev`
- Action: `secretsmanager:GetSecretValue`
- Resource: ARN của secret DB connection

Mẫu policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "<arn-secret-db-connection>"
    }
  ]
}
```

### 6.3 Runtime model sau khi chuyển Secrets Manager
- Trước đây: `ConnectionStrings__DefaultConnection` được đưa vào trường `environment` (plaintext).
- Hiện tại: `ConnectionStrings__DefaultConnection` lấy từ trường `secrets` của ECS container definition.
- Kết quả: task cần quyền IAM đọc secret; không còn nhúng mật khẩu DB trực tiếp trong task env.

## 7. Kết luận nhanh để gửi đối tác/reviewer

- Hệ thống backend đã tách role theo từng compute/workload, không dùng role chung.
- Trust policy của OIDC đã ràng buộc aud + sub theo đúng repo.
- Quyền deploy backend được giới hạn theo ECR repo cụ thể + ECS actions cần thiết + PassRole giới hạn.
- Runtime backend đã chuyển sang lấy DB connection string từ Secrets Manager qua IAM policy tối thiểu (`GetSecretValue` trên đúng secret).
- Frontend static S3 đã có cấu hình website endpoint và bucket-level public access block mở.
- Cần xác nhận lại bước apply bucket policy public-read nếu mục tiêu là public website trực tiếp từ S3.

## 8. Nguồn trích chính

- `terraform_xbrain/module/ECS_Backend/main.tf`
- `terraform_xbrain/module/GitHubActionsOIDC/main.tf`
- `terraform_xbrain/us-dev/terraform.tfstate`
- `terraform_xbrain/us-dev-static/main.tf`
- `terraform_xbrain/us-dev-static/terraform.tfstate`

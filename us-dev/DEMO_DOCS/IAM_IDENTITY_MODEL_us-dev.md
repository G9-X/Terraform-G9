# Mô hình Identity và IAM Role chi tiết - us-dev

## 1) Phạm vi và nguyên tắc thiết kế

Mô hình IAM hiện tại tách role theo đúng trách nhiệm của từng thành phần, không dùng một role chung cho toàn hệ thống.

- EC2 chạy ECS agent: role riêng cho máy chủ.
- ECS Task Execution: role riêng để ECS runtime kéo image, ghi log, đọc secret khi khởi tạo task.
- ECS Task Runtime: role riêng cho code ứng dụng trong container.
- GitHub Actions: role riêng theo cơ chế OIDC để CI/CD deploy không cần Access Key tĩnh.

Nguyên tắc chính:

- Least privilege: chỉ cấp đúng quyền cần thiết.
- Short-lived credential: dùng token tạm qua STS.
- Separation of duties: tách role deploy khỏi role runtime.

Bằng chứng wiring module theo môi trường us-dev:

- ECS backend module: [us-dev/main.tf](../main.tf#L60)
- GitHub OIDC module: [us-dev/main.tf](../main.tf#L86)

## 2) Danh sách role đã tạo trên state us-dev

Theo state hiện tại:

- xbrain-ecs-instance-us-dev: [us-dev/terraform.tfstate](../terraform.tfstate#L1190)
- xbrain-ecs-exec-us-dev: [us-dev/terraform.tfstate](../terraform.tfstate#L1232)
- xbrain-ecs-task-us-dev: [us-dev/terraform.tfstate](../terraform.tfstate#L1272)
- xbrain-gha-oidc-us-dev: [us-dev/terraform.tfstate](../terraform.tfstate#L1766)

## 3) Chi tiết từng role

### 3.1 ECS Instance Role

Role: xbrain-ecs-instance-us-dev

Trust policy:

- Chỉ cho EC2 assume role (Service Principal ec2.amazonaws.com).
- Terraform trust policy: [module/ECS_Backend/main.tf](../../module/ECS_Backend/main.tf#L40)
- Bằng chứng state: [us-dev/terraform.tfstate](../terraform.tfstate#L1179)

Policy gắn vào role:

- AmazonEC2ContainerServiceforEC2Role
- AmazonSSMManagedInstanceCore
- Terraform attachment: [module/ECS_Backend/main.tf](../../module/ECS_Backend/main.tf#L56)
- Bằng chứng state managed_policy_arns: [us-dev/terraform.tfstate](../terraform.tfstate#L1185)

Được phép:

- ECS agent trên EC2 đăng ký instance vào ECS cluster và vận hành vòng đời task.
- SSM Agent kết nối Systems Manager để quản trị không cần SSH key.

Không được phép:

- Không thể bị ECS task assume trực tiếp vì trust chỉ cho EC2.
- Không có quyền CI/CD như register task definition hoặc update ECS service.

### 3.2 ECS Task Execution Role

Role: xbrain-ecs-exec-us-dev

Trust policy:

- Chỉ cho ecs-tasks.amazonaws.com assume role.
- Terraform trust policy: [module/ECS_Backend/main.tf](../../module/ECS_Backend/main.tf#L14)
- Bằng chứng state: [us-dev/terraform.tfstate](../terraform.tfstate#L1222)

Policy gắn vào role:

- AmazonECSTaskExecutionRolePolicy.
- Inline policy cho phép đọc DB secret từ Secrets Manager.
- Terraform attachment: [module/ECS_Backend/main.tf](../../module/ECS_Backend/main.tf#L30)
- Terraform inline policy: [module/ECS_Backend/main.tf](../../module/ECS_Backend/main.tf#L35)
- Bằng chứng state: [us-dev/terraform.tfstate](../terraform.tfstate#L1228)

Được phép:

- Kéo image từ ECR khi start task.
- Ghi log lên CloudWatch Logs.
- Đọc secret để inject biến ConnectionStrings__DefaultConnection cho container.

Không được phép:

- Không phải role cho code nghiệp vụ của app gọi AWS API tùy ý.
- Không dùng để triển khai ECS service từ CI/CD.

Lưu ý quan trọng:

- Secret khai báo ở trường secrets của task definition được resolve trong bước khởi tạo task, nên quyền đọc secret cần nằm ở execution role.

### 3.3 ECS Task Role

Role: xbrain-ecs-task-us-dev

Trust policy:

- Chỉ cho ecs-tasks.amazonaws.com assume role.
- Terraform trust policy: [module/ECS_Backend/main.tf](../../module/ECS_Backend/main.tf#L35)
- Bằng chứng state: [us-dev/terraform.tfstate](../terraform.tfstate#L1264)

Policy gắn vào role:

- Hiện tại chưa gắn managed policy và chưa có inline policy.
- Bằng chứng state managed_policy_arns rỗng: [us-dev/terraform.tfstate](../terraform.tfstate#L1270)

Được phép:

- Có danh tính IAM cho task, nhưng chưa có quyền gọi AWS service nào khi chưa attach policy.

Không được phép:

- Không truy cập được S3, SQS, SES, DynamoDB, Secrets Manager, SSM Parameter Store nếu chưa cấp bổ sung.

### 3.4 GitHub Actions OIDC Role

Role: xbrain-gha-oidc-us-dev

Trust policy:

- AssumeRoleWithWebIdentity qua OIDC provider token.actions.githubusercontent.com.
- Điều kiện bắt buộc:
  - aud phải là sts.amazonaws.com
  - sub phải match repo:G9-X/Merxly-XB9:*
- Terraform trust policy: [module/GitHubActionsOIDC/main.tf](../../module/GitHubActionsOIDC/main.tf#L20)
- Bằng chứng state trust: [us-dev/terraform.tfstate](../terraform.tfstate#L1753)

Policy gắn vào role (inline):

- Quyền ECR để push image cho đúng repository backend.
- Quyền ECS để describe/register task definition, update service, describe cluster/service/task.
- iam:PassRole chỉ cho đúng 2 role runtime:
  - xbrain-ecs-task-us-dev
  - xbrain-ecs-exec-us-dev
- Terraform policy doc: [module/GitHubActionsOIDC/main.tf](../../module/GitHubActionsOIDC/main.tf#L48)
- Bằng chứng state inline policy: [us-dev/terraform.tfstate](../terraform.tfstate#L1798)

Được phép:

- Build và push image backend lên ECR.
- Đăng ký task definition revision mới.
- Update ECS service để rollout version mới.

Không được phép:

- Không có quyền assume role ngoài trust OIDC đã ràng buộc.
- Không có wildcard pass role cho toàn tài khoản.
- Không có quyền admin tổng quát.

### 3.5 Mẫu JSON policy để đối chiếu nhanh

Trust policy của ECS Instance Role (xbrain-ecs-instance-us-dev):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

Trust policy của ECS Task Execution/Task Role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

Inline policy đọc secret của Execution Role (rút gọn theo module ECS_Backend):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:<region>:<account-id>:secret:<project>/backend/<env>/db-connection*"
      ]
    }
  ]
}
```

Trust policy của GitHub Actions OIDC Role (xbrain-gha-oidc-us-dev):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
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

Inline permission policy của GitHub OIDC Role (rút gọn theo module GitHubActionsOIDC):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeImages",
        "ecr:DescribeRepositories",
        "ecr:InitiateLayerUpload",
        "ecr:ListImages",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ],
      "Resource": [
        "arn:aws:ecr:<region>:<account-id>:repository/<backend-repository-name>"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeTaskDefinition",
        "ecs:RegisterTaskDefinition",
        "ecs:UpdateService",
        "ecs:DescribeServices",
        "ecs:DescribeClusters",
        "ecs:DescribeTasks",
        "ecs:ListTasks"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": [
        "arn:aws:iam::<account-id>:role/xbrain-ecs-exec-us-dev",
        "arn:aws:iam::<account-id>:role/xbrain-ecs-task-us-dev"
      ]
    }
  ]
}
```

Lưu ý khi dùng mẫu JSON:

- Thay các placeholder như <region>, <account-id>, <project>, <env>, <backend-repository-name> theo môi trường thực tế.
- Nguồn chuẩn để đối chiếu là Terraform ở [module/ECS_Backend/main.tf](../../module/ECS_Backend/main.tf) và [module/GitHubActionsOIDC/main.tf](../../module/GitHubActionsOIDC/main.tf).

## 4) Luồng cấp quyền end-to-end

1. Developer push code lên GitHub.
2. GitHub Actions dùng OIDC lấy token tạm từ STS và assume role xbrain-gha-oidc-us-dev.
3. Workflow build/push image lên ECR.
4. Workflow đăng task definition revision mới, rồi update ECS service.
5. ECS scheduler tạo task mới trên EC2.
6. ECS dùng execution role để kéo image, ghi log, đọc secret DB.
7. App chạy với task role.

Ý nghĩa bảo mật:

- Không cần lưu Access Key tĩnh trong GitHub.
- Tách quyền deploy và quyền runtime.
- Secret DB không hardcode trong environment plaintext của container.

## 5) Chứng minh EC2 truy cập AWS bằng IAM Role only

### 5.1 Bằng chứng từ IaC

- EC2 launch template gắn instance profile thay vì key tĩnh:
  - Gắn IAM instance profile: [module/ECS_Backend/main.tf](../../module/ECS_Backend/main.tf#L76)
  - Instance profile map tới role xbrain-ecs-instance-us-dev: [module/ECS_Backend/main.tf](../../module/ECS_Backend/main.tf#L66)
  - Bằng chứng state profile-role: [us-dev/terraform.tfstate](../terraform.tfstate#L1149)

- Task definition backend không inject AWS access key vào environment:
  - Dùng trường secrets để lấy connection string từ Secrets Manager: [module/ECS_Backend/main.tf](../../module/ECS_Backend/main.tf#L185)

### 5.2 Bằng chứng vận hành (audit command)

Bước 1: Xác nhận EC2 có instance profile

```bash
aws ec2 describe-instances \
  --instance-ids <EC2_INSTANCE_ID> \
  --query 'Reservations[0].Instances[0].IamInstanceProfile.Arn' \
  --output text \
  --profile workshop --region us-east-1
```

Kỳ vọng: trả về arn instance-profile xbrain-ecs-instance-profile-us-dev.

Bước 2: Vào máy qua SSM

```bash
aws ssm start-session \
  --target <EC2_INSTANCE_ID> \
  --profile workshop --region us-east-1
```

Bước 3: Chứng minh không có key tĩnh

```bash
printenv | grep -E 'AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|AWS_SESSION_TOKEN' || true
ls -la ~/.aws || true
cat ~/.aws/credentials || true
```

Kỳ vọng: không có key tĩnh được cấu hình.

Bước 4: Chứng minh credential lấy từ IMDS

```bash
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/
ROLE_NAME=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/)
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE_NAME
aws sts get-caller-identity --region us-east-1
```

Kỳ vọng:

- Role name là xbrain-ecs-instance-us-dev.
- STS identity là assumed-role của role này.

## 6) Phân biệt nhanh để tránh nhầm role

- ECS Instance Role: role của máy EC2 để ECS Agent và SSM vận hành host.
- ECS Execution Role: role ECS dùng khi khởi tạo task (image, log, secrets).
- ECS Task Role: role app dùng khi chạy runtime.
- GitHub OIDC Role: role pipeline CI/CD dùng để deploy.

Lỗi thường gặp nếu gán sai role:

- AccessDenied lúc task khởi chạy vì thiếu quyền ở execution role.
- App chạy được nhưng gọi AWS API fail vì thiếu quyền ở task role.
- Workflow đăng task definition fail do thiếu iam:PassRole đúng ARN.

## 7) Khuyến nghị hardening thêm

1. Tách role OIDC cho frontend và backend

- Backend role chỉ có ECR backend + ECS backend.
- Frontend role chỉ có quyền S3 bucket frontend và quyền liên quan deploy static.

2. Siết điều kiện sub trong trust policy OIDC

- Có thể khóa thêm theo branch hoặc workflow thay vì để toàn repo.

3. Bổ sung guardrail

- Dùng permission boundary hoặc SCP nếu account nằm trong AWS Organization.

4. Theo dõi truy cập secret

- Bật CloudTrail + cảnh báo khi có mẫu truy cập bất thường vào secret.

## 8) Kết luận

- Mô hình backend đã tách role theo compute resource, không dùng role chia sẻ cho mọi thành phần.
- Mỗi role có trust boundary và permission boundary rõ ràng, có thể giải thích được làm gì và không được làm gì.
- EC2 và workflow CI/CD đều có thể chứng minh dùng IAM role based access thay vì access key tĩnh.

Ghi chú mở rộng:

- Workflow frontend đã chạy theo OIDC: [Merxly-XB9/.github/workflows/frontend-static.yml](../../../Merxly-XB9/.github/workflows/frontend-static.yml#L102)

# Hướng Dẫn Tạo Hạ Tầng Trên AWS Console (Theo Kiến Trúc Terraform Hiện Tại)

## 1. Mục tiêu tài liệu

Tài liệu này hướng dẫn bạn tạo hạ tầng bằng tay trên AWS Console theo đúng thiết kế đang có trong Terraform:
- Backend chạy ECS trên EC2
- Database MySQL trên RDS private
- ALB public để expose API
- CI/CD dùng GitHub Actions OIDC (không dùng access key tĩnh)
- Frontend static trên S3 website (khi account cho phép)
- Backend lấy DB connection string từ Secrets Manager

Tài liệu tập trung vào 3 thứ cho mỗi bước:
- Tạo gì
- Vì sao cần tạo
- Role và policy nào liên quan

## 2. Quy ước đặt tên (nên giữ đồng nhất)

Dùng prefix giống Terraform để dễ đối chiếu:
- Project: xbrain
- Environment backend: us-dev
- Environment frontend static: us-dev-static

Tên tài nguyên gợi ý:
- VPC: xbrain-vpc-us-dev
- ALB: xbrain-alb-us-dev
- Target Group: xbrain-tg-us-dev
- ECS Cluster: xbrain-backend-us-dev
- ECS Service: xbrain-backend-svc-us-dev
- ECS Task Family: xbrain-backend-us-dev
- ASG ECS: xbrain-ecs-asg-us-dev
- RDS: xbrain-mysql-us-dev
- ECR Repo: xbrain-backend-us-dev
- OIDC Role: xbrain-gha-oidc-us-dev
- ECS Instance Role: xbrain-ecs-instance-us-dev
- ECS Exec Role: xbrain-ecs-exec-us-dev
- ECS Task Role: xbrain-ecs-task-us-dev
- Secret DB: xbrain/backend/us-dev/db-connection

## 3. Kiến trúc tổng quan cần tạo trên Console

1. Networking
- Tạo VPC, public subnet, private app subnet, private data subnet, route tables, NAT.

2. Security
- Tạo Security Group cho ALB, ECS backend, RDS.

3. Data + Registry
- Tạo RDS MySQL private.
- Tạo ECR repository cho image backend.
- Tạo Secrets Manager secret chứa connection string.

4. Compute
- Tạo ECS Cluster kiểu EC2 capacity provider.
- Tạo EC2 Launch Template + ASG cho ECS cluster.
- Tạo Task Definition + Service gắn ALB.

5. Identity
- Tạo IAM roles riêng cho từng compute/workload.
- Tạo OIDC trust role cho GitHub Actions deploy.

6. Frontend
- Tạo S3 static website và cho CI/CD upload.

## 4. Làm từng bước trên Console

## Bước A: Tạo VPC và subnet

Mở AWS Console -> VPC -> Create VPC.

Tạo:
- 1 VPC CIDR ví dụ 10.50.0.0/16
- 2 Public subnets (2 AZ)
- 2 Private app subnets (2 AZ)
- 2 Private data subnets (2 AZ)
- Internet Gateway cho public
- NAT Gateway cho private app/private data outbound

Vì sao:
- ALB cần public subnet để nhận traffic Internet.
- ECS backend và RDS nên ở private subnet để giảm bề mặt tấn công.

## Bước B: Tạo Security Groups

### 1) ALB SG
Inbound:
- 80 từ 0.0.0.0/0
Outbound:
- all

### 2) Backend ECS SG
Inbound:
- 8080 từ ALB SG
Outbound:
- all

### 3) RDS SG
Inbound:
- 3306 từ Backend ECS SG
Outbound:
- all

Vì sao:
- Chặn kết nối trực tiếp Internet vào ECS/RDS.
- Chỉ cho luồng ALB -> ECS -> RDS.

## Bước C: Tạo ECR repository

Mở ECR -> Create repository:
- Name: xbrain-backend-us-dev
- Mutable tags: tùy chọn
- Encryption: AES256 mặc định

Vì sao:
- Nơi lưu image backend để ECS pull khi deploy.

## Bước D: Tạo RDS MySQL

Mở RDS -> Create database:
- Engine: MySQL
- DB identifier: xbrain-mysql-us-dev
- Master username: ví dụ rdsxbrain
- Password: đặt mạnh
- VPC: chọn VPC vừa tạo
- Subnet group: private data subnets
- Public access: No
- SG: chọn RDS SG
- Initial DB name: xbrain

Vì sao:
- Dữ liệu nằm ở private network, không mở public.

## Bước E: Tạo Secrets Manager secret cho DB connection

Mở Secrets Manager -> Store a new secret:
- Secret type: Other type of secret
- Key/Value:
  - name: connection_string
  - value: Server=<rds-endpoint>;Port=3306;Database=xbrain;User=rdsxbrain;Password=<password>;SslMode=Preferred;
- Secret name: xbrain/backend/us-dev/db-connection

Vì sao:
- Không nhúng password DB trực tiếp trong task definition/env plain text.

Lưu ý runtime ECS:
- Ở task definition, bạn map secret vào biến môi trường ConnectionStrings__DefaultConnection.

## Bước F: Tạo IAM roles (Identity Model)

## 1) ECS Instance Role

Tên role: xbrain-ecs-instance-us-dev
Trusted entity: AWS service -> EC2

Attach managed policies:
- AmazonEC2ContainerServiceforEC2Role
- AmazonSSMManagedInstanceCore

Tạo Instance Profile:
- xbrain-ecs-instance-profile-us-dev
- gắn role xbrain-ecs-instance-us-dev

Vì sao:
- EC2 phải đăng ký vào ECS cluster và dùng SSM để vận hành.

## 2) ECS Task Execution Role

Tên role: xbrain-ecs-exec-us-dev
Trusted entity: ECS Tasks

Attach managed policy:
- AmazonECSTaskExecutionRolePolicy

Thêm inline policy đọc secret DB:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:us-east-1:<ACCOUNT_ID>:secret:xbrain/backend/us-dev/db-connection*"
    }
  ]
}
```

Vì sao:
- ECS runtime cần pull image/logging.
- Và cần lấy secret DB để inject vào container.

## 3) ECS Task Role

Tên role: xbrain-ecs-task-us-dev
Trusted entity: ECS Tasks

Policy:
- Ban đầu có thể để trống nếu app không gọi AWS API trực tiếp.

Vì sao:
- Tách quyền runtime business logic khỏi execution role.

## 4) GitHub Actions OIDC Role

Tên role: xbrain-gha-oidc-us-dev
Trusted entity: Web identity
OIDC provider: token.actions.githubusercontent.com

Trust policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
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

Permission policy gợi ý:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
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
      "Resource": "arn:aws:ecr:us-east-1:<ACCOUNT_ID>:repository/xbrain-backend-us-dev"
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
      "Action": "iam:PassRole",
      "Resource": [
        "arn:aws:iam::<ACCOUNT_ID>:role/xbrain-ecs-exec-us-dev",
        "arn:aws:iam::<ACCOUNT_ID>:role/xbrain-ecs-task-us-dev"
      ]
    }
  ]
}
```

Vì sao:
- CI/CD deploy không cần access key tĩnh.
- Role bị giới hạn đúng repo + đúng quyền deploy.

## Bước G: Tạo ALB + Target Group

Mở EC2 -> Load Balancers -> Create ALB:
- Internet-facing
- Subnets: public
- SG: ALB SG
- Listener: HTTP 80

Tạo Target Group:
- Type: IP (cho ECS awsvpc)
- Protocol: HTTP
- Port: 8080
- Health check path: /health

Vì sao:
- Cấp endpoint public ổn định cho frontend/caller.

## Bước H: Tạo ECS Cluster EC2 + ASG + Capacity Provider

### 1) Tạo ECS Cluster
- Name: xbrain-backend-us-dev
- Infrastructure: EC2 (cụm ECS dùng máy EC2 của bạn, không phải Fargate)

### 2) Tạo Launch Template EC2
- AMI: ECS-optimized Amazon Linux 2
- Instance type: t3.small
- IAM instance profile: xbrain-ecs-instance-profile-us-dev (gói để gắn IAM role vào EC2 khi ASG tạo máy mới)
- SG: Backend ECS SG
- User data:
```bash
#!/bin/bash
echo ECS_CLUSTER=xbrain-backend-us-dev >> /etc/ecs/ecs.config
echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
```
- Metadata options: IMDSv2 required (bắt buộc token metadata, an toàn hơn IMDSv1)

### 3) Tạo ASG
- Name: xbrain-ecs-asg-us-dev
- Subnets: private app
- Desired/min/max tùy nhu cầu (số EC2 mong muốn/tối thiểu/tối đa)
- Gắn Launch Template

### 4) Tạo Capacity Provider
- Name: xbrain-cp-us-dev
- Link ASG ở trên
- Bật managed scaling (ECS tự điều chỉnh ASG theo nhu cầu task)

Giải thích kỹ:
- Capacity Provider là lớp điều phối giữa ECS Scheduler và ASG.
- Khi service cần thêm task, ECS không tự tạo EC2 trực tiếp mà yêu cầu Capacity Provider tăng/giảm ASG theo nhu cầu.
- Managed scaling giúp ECS tự động tính toán cần bao nhiêu EC2 để đủ chỗ chạy task (dựa trên CPU/memory task).
- Nếu không dùng capacity provider, bạn phải tự canh desired capacity của ASG thủ công và rất dễ thiếu máy hoặc thừa máy.
- Cấu hình khuyến nghị khi demo:
  - Managed scaling: ENABLED
  - Target capacity: 100
  - Managed termination protection: DISABLED (đơn giản cho workshop)

### 5) Gắn capacity provider vào cluster
- Đặt default strategy weight/base phù hợp (quy tắc chia task lên capacity provider)

Giải thích kỹ base/weight:
- base là số task tối thiểu phải chạy trên capacity provider đó trước khi áp dụng weight.
- weight là tỉ lệ phân bổ task giữa nhiều capacity provider.
- Với 1 capacity provider duy nhất (xbrain-cp-us-dev), cấu hình đơn giản nhất:
  - base = 1
  - weight = 1
- Ý nghĩa: luôn cố gắng có ít nhất 1 task khởi chạy trên provider này và toàn bộ task còn lại cũng chạy trên chính provider đó.
- Khi nào cần nhiều provider:
  - Ví dụ mix On-Demand + Spot để tối ưu chi phí.
  - Lúc đó weight dùng để chia tỷ lệ chạy giữa các nhóm máy.

Vì sao:
- ECS sẽ có compute capacity từ EC2 theo ASG.
- Cluster không còn phụ thuộc thao tác scale EC2 thủ công mỗi lần tăng/giảm task.
- Giảm rủi ro trạng thái "service muốn chạy task nhưng không có EC2 đủ tài nguyên".

## Bước I: Tạo ECS Task Definition backend

Mở ECS -> Task Definitions -> Create:
- Family: xbrain-backend-us-dev
- Launch type compatibility: EC2 (task chạy trên ECS container instances)
- Network mode: awsvpc (task có ENI/IP riêng trong VPC)
- Task execution role: xbrain-ecs-exec-us-dev (role cho pull image/log/đọc secret khi task khởi chạy)
- Task role: xbrain-ecs-task-us-dev (role cho code ứng dụng gọi AWS API lúc runtime)

Container backend:
- Image: <account>.dkr.ecr.us-east-1.amazonaws.com/xbrain-backend-us-dev:<tag>
- Port mapping: 8080
- Env:
  - ASPNETCORE_URLS = http://+:8080
  - ASPNETCORE_ENVIRONMENT = us-dev
- Secrets:
  - Name: ConnectionStrings__DefaultConnection
  - ValueFrom: ARN secret xbrain/backend/us-dev/db-connection (ECS inject secret vào env lúc start container)
- Log driver: awslogs

Vì sao:
- Container lấy DB connection từ Secrets Manager thay vì plaintext.

## Bước J: Tạo ECS Service

Mở ECS Cluster -> Create service:
- Service name: xbrain-backend-svc-us-dev
- Task definition: xbrain-backend-us-dev
- Capacity provider strategy: xbrain-cp-us-dev (service lấy compute qua capacity provider này)
- Desired count: 1 (số task backend cần chạy ổn định)
- Network:
  - Subnets: private app
  - SG: Backend ECS SG
  - Assign public IP: disabled (task chỉ chạy private, ra Internet qua NAT nếu cần)
- Load balancing:
  - ALB + target group xbrain-tg-us-dev
  - container backend:8080 (map traffic từ target group vào cổng app trong container)

Vì sao:
- Duy trì số bản chạy mong muốn và gắn vào ALB.

## Bước K: GitHub Actions cấu hình cần đặt

Trong GitHub repo settings:

Variables:
- WORKSHOP_AWS_ROLE_ARN = arn role OIDC (workflow sẽ assume role này để deploy)
- WORKSHOP_AWS_REGION = us-east-1 (region chạy hạ tầng)
- WORKSHOP_ECS_CLUSTER_NAME = xbrain-backend-us-dev (tên cluster đích)
- WORKSHOP_ECS_SERVICE_NAME = xbrain-backend-svc-us-dev (service backend cần update)
- WORKSHOP_ECS_TASK_FAMILY = xbrain-backend-us-dev (family để đăng ký revision task mới)
- WORKSHOP_ECR_REPOSITORY_NAME = xbrain-backend-us-dev (repo push image)
- WORKSHOP_BACKEND_CONTAINER_NAME = backend (container sẽ được thay image)
- WORKSHOP_RUN_DB_MIGRATION = true hoặc false (bật/tắt bước dotnet ef trong CI)
- VITE_API_BASE_URL = http://<alb-dns>/api (base URL để frontend gọi backend)

Secrets:
- S3_BUCKET_NAME nếu deploy frontend S3 (bucket chứa file build FE)
- Có thể giữ WORKSHOP_BACKEND_DB_CONNECTION_STRING cho bước migration CI nếu workflow vẫn dùng dotnet ef trực tiếp (không dùng cho runtime ECS sau khi đã chuyển Secrets Manager)

Vì sao:
- Workflow cần tên tài nguyên để build/push/deploy đúng môi trường.

## Bước L: Frontend S3 static website

Mở S3 -> Create bucket:
- Name: xbrain-static-xxxxx
- Region: us-east-1
- Tắt block public access ở bucket nếu muốn public website

Bật website hosting:
- Index: index.html
- Error: index.html

Bucket policy public-read:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::<BUCKET_NAME>/*"
    }
  ]
}
```

Upload build:
- aws s3 sync dist s3://<BUCKET_NAME> --delete

Vì sao:
- Host frontend nhanh, rẻ, đơn giản.

Lưu ý workshop account:
- Nếu account-level guardrail chặn public policy thì website sẽ không public được dù bucket-level mở.

## Phụ lục A: Giải thích sâu toàn bộ luồng A-L

Phần này dùng khi bạn cần giải thích chi tiết trong buổi bảo vệ hoặc bị hỏi vì sao phải tạo từng tài nguyên.

### A) VPC và subnet
- Tạo để tách lớp mạng theo vai trò: public nhận traffic, private chạy workload, private-data chứa database.
- Nếu đặt ECS hoặc RDS ở public subnet, bề mặt tấn công tăng mạnh.
- Kiểm tra nhanh: ALB public truy cập được, còn ECS/RDS không có public IP.

### B) Security Group
- Tạo để kiểm soát đường đi lưu lượng ở lớp network.
- Rule tối thiểu cần giữ:
  - Internet chỉ vào ALB:80
  - ALB SG mới được vào ECS:8080
  - ECS SG mới được vào RDS:3306
- Nếu mở sai rule, thường gặp 2 lỗi: health check fail hoặc DB timeout.

### C) ECR
- Tạo để lưu image versioned cho backend.
- ECS không build code, ECS chỉ kéo image đã được CI push lên ECR.
- Kiểm tra nhanh: repo có tag SHA mới sau mỗi lần workflow backend chạy.

### D) RDS MySQL
- Tạo để lưu dữ liệu nghiệp vụ bền vững.
- RDS nên private để chỉ backend truy cập qua SG.
- Kiểm tra nhanh: endpoint resolve nội bộ, app query thành công, không mở public access.

### E) Secrets Manager
- Tạo để tách secret ra khỏi code, task env plaintext và Git history.
- Secret DB connection dùng cho runtime container.
- Kiểm tra nhanh: execution role có quyền GetSecretValue đúng ARN secret.

### F) IAM roles
- Tạo theo nguyên tắc least privilege, mỗi vai trò một quyền riêng.
- ECS Instance role: quyền cho EC2 agent + SSM vận hành.
- ECS Execution role: quyền pull image, ghi log, đọc secret runtime.
- ECS Task role: quyền cho business code gọi AWS API (nếu cần thêm sau).
- GitHub OIDC role: quyền deploy CI/CD, không dùng access key tĩnh.

### G) ALB + Target Group
- Tạo để publish backend ra Internet theo 1 endpoint ổn định.
- Target group kiểu IP bắt buộc khi ECS dùng awsvpc.
- Health check path /health giúp tách kiểm tra liveness khỏi API nghiệp vụ.

### H) ECS EC2 + ASG + Capacity Provider
- Đây là lớp compute thực thi container backend.
- ASG cung cấp số lượng máy EC2; Capacity Provider giúp ECS tự phối hợp scale theo nhu cầu task.
- Nếu chỉ có ASG mà không nối đúng capacity provider/strategy, service có thể không scale đúng kỳ vọng.

### I) Task Definition
- Đây là bản khai runtime của container: image, port, env, secrets, log.
- Mỗi lần deploy mới thường tạo revision mới của task definition.
- Secret DB phải nằm trong mục secrets thay vì environment để tránh lộ plaintext.

### J) ECS Service
- Tạo để duy trì desired count và tự thay task lỗi.
- Service gắn ALB để đăng ký/deregister target tự động khi rollout.
- Kiểm tra nhanh: desired = running và target group có trạng thái healthy.

### K) GitHub variables/secrets
- Tạo để workflow biết đúng tên tài nguyên môi trường và deploy đúng account/region.
- Backend deploy dùng OIDC role ARN + region + ECS/ECR identifiers.
- Frontend build dùng VITE_API_BASE_URL để FE gọi đúng BE.

### L) Frontend S3 static
- Tạo để host frontend đơn giản, chi phí thấp.
- Nếu account chặn public policy ở cấp guardrail, cần phương án thay thế (CloudFront account khác hoặc mô hình host khác).
- Kiểm tra nhanh: website endpoint trả được file tĩnh và FE gọi API không bị CORS.

## 5. CORS bắt buộc để FE gọi BE

Trong backend, cần cho phép origin của frontend S3 website hoặc domain frontend.

Nếu không thêm origin đúng, browser sẽ báo CORS dù API chạy tốt.

## 6. Checklist nghiệm thu sau khi tạo xong

1. ALB health check /health trả healthy.
2. API test được:
- http://<alb-dns>/api/Products?pageNumber=1&pageSize=5
3. ECS service có desired = running.
4. Task log không còn lỗi DB connection.
5. Secrets Manager secret đọc được bởi execution role.
6. Frontend build gọi đúng VITE_API_BASE_URL.

## 7. Tóm tắt vai trò và policy theo đúng tư duy least privilege

- xbrain-ecs-instance-us-dev:
  - Dùng cho EC2/ECS agent + SSM vận hành.

- xbrain-ecs-exec-us-dev:
  - Dùng cho runtime ECS (ECR/Logs) + đọc đúng 1 secret DB.

- xbrain-ecs-task-us-dev:
  - Dùng cho code ứng dụng; mặc định để rỗng, chỉ thêm quyền khi thực sự cần.

- xbrain-gha-oidc-us-dev:
  - Dùng cho GitHub Actions deploy backend qua OIDC.
  - Bị ràng buộc repo và chỉ pass đúng task roles cần thiết.

Kết quả:
- Tách biệt quyền theo trách nhiệm.
- Giảm rủi ro lộ secret trong code/env.
- Vận hành được bằng Console nhưng vẫn bám sát chuẩn IaC hiện có.

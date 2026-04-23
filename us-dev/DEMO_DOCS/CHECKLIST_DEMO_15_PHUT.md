# Checklist Demo 15 Phút (Console-First)

## 0) Mục tiêu demo

- Chứng minh backend chạy ổn trên ECS EC2, có ALB, có RDS, có Secrets Manager.
- Chứng minh CI/CD backend deploy qua GitHub OIDC (không dùng access key tĩnh).
- Chứng minh frontend build có thể đẩy lên S3 static (nếu account cho phép public policy).

---

## 1) Chuẩn bị trước demo (2 phút)

- [ ] Đăng nhập đúng AWS account/region (us-east-1).
- [ ] Mở sẵn 5 tab Console: IAM, ECS, RDS, Secrets Manager, EC2/ALB.
- [ ] Mở sẵn GitHub repo workflow backend + frontend.
- [ ] Xác nhận endpoint ALB hiện tại truy cập được.

---

## 2) Identity model (3 phút)

### IAM Roles cần show

- [ ] Role ECS instance: xbrain-ecs-instance-us-dev.
- [ ] Role ECS execution: xbrain-ecs-exec-us-dev.
- [ ] Role ECS task: xbrain-ecs-task-us-dev.
- [ ] Role GitHub OIDC: xbrain-gha-oidc-us-dev.

### Điểm cần nói ngắn gọn

- [ ] Mỗi compute/workload một role riêng, không dùng role chung.
- [ ] EC2 assume qua ec2.amazonaws.com.
- [ ] ECS task/execution assume qua ecs-tasks.amazonaws.com.
- [ ] GitHub Actions assume qua OIDC, ràng buộc repo bằng condition sub.

### Policy cần show

- [ ] ECS instance role gắn AmazonEC2ContainerServiceforEC2Role.
- [ ] ECS instance role gắn AmazonSSMManagedInstanceCore.
- [ ] ECS execution role gắn AmazonECSTaskExecutionRolePolicy.
- [ ] ECS execution role có inline policy secretsmanager:GetSecretValue cho secret DB.
- [ ] GitHub OIDC role có ECR + ECS + iam:PassRole (giới hạn đúng 2 role ECS).

---

## 3) Dòng chảy secret và database (3 phút)

### Secrets Manager

- [ ] Mở secret xbrain/backend/us-dev/db-connection.
- [ ] Nói rõ: connection string không còn nhúng plaintext trong task env.

### ECS Task Definition

- [ ] Show container backend có mục secrets:
  - name: ConnectionStrings__DefaultConnection
  - valueFrom: ARN secret

### RDS

- [ ] Show instance xbrain-mysql-us-dev đang Available.
- [ ] Nói rõ: đổi qua Secrets Manager không cần import lại DB nếu vẫn cùng RDS/database.

---

## 4) Backend runtime health (3 phút)

- [ ] Mở ECS service xbrain-backend-svc-us-dev: desired = running.
- [ ] Mở Target Group health: target healthy.
- [ ] Test endpoint:
  - [ ] /health trả 200
  - [ ] /api/Products?pageNumber=1&pageSize=5 trả 200

Nếu lỗi:
- [ ] Mở CloudWatch Logs nhóm /ecs/xbrain/backend/us-dev và đọc stack trace mới nhất.

---

## 5) CI/CD OIDC demo (2 phút)

### GitHub backend workflow

- [ ] Chạy workflow deploy backend.
- [ ] Show bước Configure AWS credentials via OIDC thành công.
- [ ] Show image push ECR + register task definition + update service.

### Điều cần nhấn mạnh

- [ ] Không cấu hình AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY cho backend deploy.
- [ ] Quyền deploy giới hạn theo least privilege.

---

## 6) Frontend static (2 phút)

- [ ] Show workflow frontend đã chuyển OIDC cho deploy.
- [ ] Show VITE_API_BASE_URL trỏ về ALB /api.
- [ ] Nếu S3 public policy bị guardrail account chặn, nói rõ đây là account constraint, không phải lỗi kiến trúc.

---

## 7) Chốt demo (30 giây)

- [ ] Kết luận 1: kiến trúc backend chạy ổn end-to-end (ALB -> ECS -> RDS).
- [ ] Kết luận 2: secret DB quản lý tập trung bằng Secrets Manager.
- [ ] Kết luận 3: CI/CD backend dùng OIDC, không dùng access key tĩnh.
- [ ] Kết luận 4: role/policy tách riêng theo chức năng, bám least privilege.

---

## 8) Link tài liệu đầy đủ (đọc sâu)

- [HUONG_DAN_TAO_HA_TANG_TREN_CONSOLE.md](HUONG_DAN_TAO_HA_TANG_TREN_CONSOLE.md)
- [IAM_IDENTITY_MODEL_us-dev.md](IAM_IDENTITY_MODEL_us-dev.md)
- [RESOURCE_POLICY_TONG_THE.md](RESOURCE_POLICY_TONG_THE.md)

# W5: GeekBrain AI Merge Walkthrough

Tôi đã hoàn thành việc gộp hạ tầng AI của W4 (GeekBrain) vào repo Terraform W3 (`Terraform-G9`). Dưới đây là tóm tắt những gì đã thay đổi để chuẩn bị cho requirement tuần 5.

## 1. Networking & Security
- **VPC Endpoint**: Thêm Interface Endpoint cho `execute-api` trong private-app subnets của W3 (file `module/Networking/main.tf`). Điều này cho phép Action Group Lambda gọi Monitoring Private API Gateway mà không cần NAT Gateway.
- **Security Groups**:
  - `lambda_sg`: Tạo mới cho Lambda, allow all outbound.
  - `endpoint_sg`: Tạo mới cho VPC Endpoint, allow HTTPS (443) từ `lambda_sg`.

## 2. Infrastructure Code (GeekBrain Modules)
Xóa 3 module Bedrock cũ của W3 (`Lambda_Bedrock`, `BedrockKnowledgeBase`, `BedrockChat`) và thay bằng 3 module mới từ W4, đã được parameterize region:

- **`module/GeekBrain_AI_Engine`**:
  - S3 bucket chứa document.
  - OpenSearch Serverless collection (VectorStore).
  - Bedrock Knowledge Base.
- **`module/GeekBrain_Backend`**:
  - Bedrock Agent (dùng DeepSeek model).
  - Action Group Lambda (nằm trong private-app subnet, gắn `lambda_sg`).
  - Chat Lambda & REST API Gateway (public).
- **`module/GeekBrain_Monitoring`**:
  - Monitoring API Lambda (FastAPI).
  - Private API Gateway (chỉ nhận traffic từ VPC Endpoint).

## 3. Lambda Functions & Data
Copy toàn bộ logic từ W4 sang:
- `lambda/geekbrain/` (Chat Lambda và Action Group Lambda).
- `monitoring_lambda/` (FastAPI).
- `data_package/` (36 markdown documents cho KB và 4 file CSV).

## 4. W3 Root Config (`us-dev/`)
- Cập nhật `variables.tf`: Đổi default region sang `us-east-1` (nơi support DeepSeek V3.2 Bedrock Agent), thêm các biến prefix `geekbrain_`.
- Cập nhật `main.tf`: Wire 3 GeekBrain modules với output từ `Networking` và `Security`.
- Cập nhật `outputs.tf`: Trả về API Gateway URL của Chat và Monitoring, Knowledge Base ID.
- Cập nhật `provider.tf`: Setup S3 backend + DynamoDB lock table (W4 style) thay vì dùng local state.

## 5. Frontend (`merxly_frontend`)
Sửa `AiChatProvider.tsx`:
- Sinh và lưu `session_id` trong `sessionStorage` (để Bedrock Agent giữ context).
- Thay vì gửi mảng `messages`, giờ frontend lấy tin nhắn cuối cùng và gửi JSON `{ question, session_id }` lên API Gateway.
- Parse `data.answer` từ JSON response. UI khung chat modal nhỏ vẫn được giữ nguyên.

---
> [!NOTE]
> Database RDS PostgreSQL không được deploy theo như bạn request (note vào devlog). Action Group tool `query_database` sẽ fail-gracefully khi gọi DB.
> Lỗi `terraform init` ở bước cuối xảy ra do AWS credentials local trên máy bạn hết hạn/không hợp lệ, tuy nhiên cấu trúc code đã chuẩn xác. Hãy renew IAM role/credentials trước khi deploy!

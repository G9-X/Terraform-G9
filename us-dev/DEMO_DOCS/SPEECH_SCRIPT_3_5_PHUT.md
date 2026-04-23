# Kịch Bản Nói 3-5 Phút (Demo Hệ Thống)

## Mở đầu (20-30 giây)

Xin chào mọi người, em trình bày nhanh kiến trúc triển khai backend và frontend của dự án trên AWS.
Mục tiêu của bản demo là chứng minh 4 điểm chính:
- Hệ thống chạy end-to-end ổn định.
- Quyền IAM tách riêng theo từng thành phần, không dùng role dùng chung.
- CI/CD backend dùng OIDC, không dùng access key tĩnh.
- Secret database được quản lý bằng AWS Secrets Manager.

## Phần 1: Kiến trúc tổng quan (40-60 giây)

Luồng hệ thống hiện tại như sau:
- Client gọi vào ALB public.
- ALB forward về ECS service chạy trên EC2 trong private subnet.
- Backend kết nối RDS MySQL trong private data subnet.
- Image backend nằm trên ECR.
- Backend lấy `ConnectionStrings__DefaultConnection` từ Secrets Manager.

Điểm quan trọng là dữ liệu và backend đều không mở public trực tiếp, chỉ ALB public để nhận traffic.

## Phần 2: Identity model và policy (60-90 giây)

Em tách role theo đúng trách nhiệm:
- `xbrain-ecs-instance-us-dev`: dành cho EC2 container instance, có quyền ECS agent + SSM.
- `xbrain-ecs-exec-us-dev`: dành cho execution runtime của ECS task, có quyền pull image/log và đọc đúng secret DB.
- `xbrain-ecs-task-us-dev`: dành cho code ứng dụng trong container, mặc định không mở rộng quyền nếu chưa cần.
- `xbrain-gha-oidc-us-dev`: dành cho GitHub Actions deploy backend qua OIDC.

Với role OIDC, trust policy có điều kiện `aud` và `sub`, nên chỉ workflow của repo đúng mới assume được role.
Về permission, role này chỉ có quyền ECR + ECS cần thiết và `iam:PassRole` chỉ giới hạn vào đúng 2 role ECS task/execution.

## Phần 3: Secrets Manager và migration (40-60 giây)

Trước đây connection string DB có thể nằm trong env plaintext.
Hiện tại em chuyển sang Secrets Manager:
- Secret lưu tại `xbrain/backend/us-dev/db-connection`.
- Task definition map secret này vào biến `ConnectionStrings__DefaultConnection`.
- Execution role có policy `secretsmanager:GetSecretValue` trên đúng ARN secret.

Lưu ý vận hành:
- Đổi sang Secrets Manager cần redeploy task để nhận secret mới.
- Không cần import lại database nếu vẫn dùng cùng RDS và cùng database.

## Phần 4: Chứng minh hệ thống chạy (40-60 giây)

Trong demo em kiểm tra nhanh:
- ECS service có `desired = running`.
- Target group health check `/health` là healthy.
- API endpoint `/api/Products?pageNumber=1&pageSize=5` trả về dữ liệu.
- Trên DB có đủ bảng và có dữ liệu mẫu.

Điều này xác nhận luồng ALB -> ECS -> RDS đang chạy ổn.

## Phần 5: CI/CD và frontend (30-45 giây)

Backend deploy workflow đã chạy theo OIDC.
Frontend cũng đã chuyển workflow sang assume role OIDC để deploy S3.
Nếu account workshop chặn S3 public policy ở cấp guardrail, frontend public website có thể bị giới hạn bởi policy account, không phải do sai kiến trúc pipeline.

## Kết luận (20-30 giây)

Tóm lại, hệ thống đạt các mục tiêu chính:
- Chạy ổn định end-to-end.
- Bảo mật tốt hơn nhờ tách role theo trách nhiệm và dùng Secrets Manager.
- CI/CD dùng OIDC, giảm rủi ro lộ access key tĩnh.

Em sẵn sàng đi sâu vào từng phần IAM policy, ECS runtime hoặc workflow deploy nếu thầy/cô muốn kiểm tra chi tiết.

# Triển khai web tĩnh trên AWS Console

Tài liệu này mô tả các bước deploy web tĩnh bằng AWS Console, kèm danh sách quyền IAM cần cấp và lý do cấp quyền.

## Phạm vi và dịch vụ sử dụng

- Lưu file web: Amazon S3 (static hosting)
- Phát hành toàn cầu: Amazon CloudFront (khuyến nghị)
- Tên miền: Route 53 (tùy chọn)
- SSL/TLS: AWS Certificate Manager (ACM) (tùy chọn nếu dùng custom domain)

## Điều kiện tiên quyết

- Bạn có bộ file build tĩnh (ví dụ: dist/ hoặc build/)
- Có quyền truy cập AWS Console và IAM

## Các bước deploy (AWS Console)

### 1) Tạo S3 bucket

1. Mở AWS Console > S3 > Create bucket.
2. Đặt tên bucket (nên trùng với domain nếu dùng custom domain).
3. Region: chọn region gần người dùng.
4. Block Public Access:
   - Nếu dùng CloudFront, có thể GIỮ block public access và dùng OAC.
   - Nếu chỉ dùng S3 static hosting, cần mở public access và dùng bucket policy.
5. Create bucket.

### 2) Upload file web

1. Vào bucket > Objects > Upload.
2. Upload toàn bộ file build.

### 3) (Khuyến nghị) Tạo CloudFront Distribution

1. Mở CloudFront > Create distribution.
2. Origin domain: chọn S3 bucket (REST endpoint), không chọn endpoint static hosting.
3. Origin access: chọn OAC (Origin Access Control) và tạo mới nếu chưa có.
4. Default root object: index.html.
5. Cache policy: dùng default hoặc tùy chỉnh nếu cần.
6. Create distribution.
7. Cập nhật bucket policy theo OAC (CloudFront sẽ đề xuất policy).

### 4) (Tùy chọn) Gắn domain và SSL

1. Mở ACM (us-east-1 cho CloudFront) > Request certificate.
2. Xác minh domain (DNS validation).
3. Quay lại CloudFront > Edit distribution > Alternate domain names (CNAMEs) và chọn certificate.
4. Nếu dùng Route 53, tạo record A/AAAA alias tới CloudFront distribution.

### 5) Kiểm tra và invalidate cache

1. Truy cập URL CloudFront hoặc S3 endpoint.
2. Khi cập nhật file, vào CloudFront > Distributions > chọn distribution > Invalidations > Create invalidation.
3. Paths khuyến nghị:
  - Deploy toàn bộ: `/*`
  - Tối ưu chi phí: chỉ invalidate `/` và `/index.html` (khi asset đã hash tên file).

### 6) Có thể "đưa invalidate vào cấu hình" khi thao tác Console không?

- Có thể đưa vào quy trình thao tác chuẩn trên Console (mỗi lần upload xong thì tạo invalidation).
- Không có tùy chọn trong CloudFront Distribution để tự động invalidate ngay sau khi S3 thay đổi.
- Nếu muốn tự động hoàn toàn, cần pipeline/script (ví dụ GitHub Actions, CodeBuild) gọi `CreateInvalidation` sau bước upload.

## Danh sách quyền IAM cần cấp và lý do

### Mục tiêu quyền

- Cho phép tạo và cấu hình S3 bucket
- Cho phép tạo và cấu hình CloudFront distribution
- Nếu có domain, cho phép quản lý ACM và Route 53

### Quyền tối thiểu (gợi ý)

#### 1) Amazon S3

- s3:CreateBucket
  - Lý do: tạo bucket cho website
- s3:PutBucketWebsite
  - Lý do: bật static website hosting
- s3:PutBucketPolicy
  - Lý do: cấp quyền public hoặc CloudFront OAC
- s3:PutBucketPublicAccessBlock
  - Lý do: bật/tắt block public access theo kiểu deploy
- s3:PutBucketTagging
  - Lý do: gắn tag theo quy ước
- s3:ListBucket
  - Lý do: xem danh sách object
- s3:PutObject, s3:DeleteObject, s3:GetObject
  - Lý do: upload, cập nhật, kiểm tra file

#### 2) Amazon CloudFront

- cloudfront:CreateDistribution
  - Lý do: tạo distribution
- cloudfront:GetDistribution, cloudfront:GetDistributionConfig
  - Lý do: xem cấu hình
- cloudfront:UpdateDistribution
  - Lý do: cập nhật origin, domain, cache
- cloudfront:CreateInvalidation
  - Lý do: xóa cache khi deploy mới
- cloudfront:TagResource, cloudfront:UntagResource
  - Lý do: quản lý tag

#### 3) AWS Certificate Manager (ACM) (tùy chọn)

- acm:RequestCertificate
  - Lý do: tạo SSL/TLS certificate
- acm:DescribeCertificate
  - Lý do: xem trạng thái xác minh
- acm:ListCertificates
  - Lý do: chọn certificate khi gắn vào CloudFront
- acm:DeleteCertificate
  - Lý do: dọn dẹp certificate không còn dùng

#### 4) Route 53 (tùy chọn)

- route53:ListHostedZones
  - Lý do: xem hosted zone
- route53:ChangeResourceRecordSets
  - Lý do: tạo/đổi record trỏ tới CloudFront
- route53:GetChange
  - Lý do: kiểm tra trạng thái cập nhật DNS

#### 5) IAM (nếu cần tạo user/role)

- iam:CreateUser, iam:CreateRole
  - Lý do: tạo user/role deploy
- iam:AttachUserPolicy, iam:AttachRolePolicy, iam:PutUserPolicy, iam:PutRolePolicy
  - Lý do: gắn policy deploy
- iam:GetUser, iam:GetRole
  - Lý do: kiểm tra thông tin

## Lưu ý về bảo mật

- Ưu tiên dùng CloudFront + OAC, giữ S3 bucket private.
- Nếu buộc phải public, chỉ cấp public read cho path web và không lưu thông tin nhạy cảm.
- Dùng tag để quản lý chi phí và tuân thủ.

## Kiểm tra nhanh sau deploy

- Mở URL CloudFront hoặc S3 endpoint, kiểm tra trang index.
- Kiểm tra console errors trong browser devtools.
- Xác minh CloudFront cache hoạt động và invalidation hoàn tất.

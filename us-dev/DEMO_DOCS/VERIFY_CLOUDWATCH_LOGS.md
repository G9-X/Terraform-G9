# Verify CloudWatch Logs — ECS Backend

**Log group:** `/ecs/xbrain/backend/us-dev`
**Region:** `us-east-1`
**Retention:** 14 ngày
**Stream prefix:** `ecs`

---

## 1. Terraform output

```bash
terraform -chdir=us-dev output cloudwatch_log_group_name
```

---

## 2. AWS Console

1. CloudWatch → **Log groups** → `/ecs/xbrain/backend/us-dev`
2. Filter stream theo prefix `ecs/backend/` → chọn stream mới nhất (sort by Last event)
3. Filter pattern nhanh: `ERROR` hoặc `Exception`

---

## 3. AWS CLI

```bash
# Lấy log stream mới nhất
aws logs describe-log-streams \
  --log-group-name /ecs/xbrain/backend/us-dev \
  --order-by LastEventTime --descending \
  --max-items 1 \
  --query 'logStreams[0].logStreamName' \
  --output text \
  --region us-east-1

# Đọc logs từ stream đó
aws logs get-log-events \
  --log-group-name /ecs/xbrain/backend/us-dev \
  --log-stream-name <stream-name> \
  --limit 50 \
  --region us-east-1

# Filter lỗi nhanh
aws logs filter-log-events \
  --log-group-name /ecs/xbrain/backend/us-dev \
  --filter-pattern "Exception" \
  --region us-east-1
```


## Build Steps

### Phase 1: S3 Buckets
- [ ] Create raw, curated, scripts buckets
- [ ] Add lifecycle rules

### Phase 2: Lambda API Ingestion
- [ ] Write Lambda to fetch API data
- [ ] Store JSON in S3 raw/
- [ ] Test locally

### Phase 3: Glue Transformation
- [ ] Write PySpark job to clean data
- [ ] Write Parquet to curated/
- [ ] Test with sample data

### Phase 4: Orchestration
- [ ] Design Step Functions workflow
- [ ] Connect Lambda → Glue
- [ ] Add error handling

### Phase 5: Automation
- [ ] Add EventBridge schedule
- [ ] Configure Glue Crawler
- [ ] Test end-to-end

## Quick Deploy

```bash
# 1. Package Lambda
./scripts/package.sh

# 2. Deploy infrastructure
cd infrastructure/terraform
terraform init
terraform apply

# 3. Test
aws stepfunctions start-execution \
  --state-machine-arn <arn>
# Scheduled ETL Pipeline

A serverless, scheduled ETL pipeline that extracts data from a public API, transforms it using AWS Glue, and makes it queryable via Athena.

## Repo Structure

```sh
scheduled-etl-pipeline/
├── README.md
├── docs/
│   ├── ARCHITECTURE.md
│   ├── API_GUIDE.md
│   ├── GLUE_GUIDE.md
│   ├── STEP_FUNCTIONS_GUIDE.md
│   └── TROUBLESHOOTING.md
├── infrastructure/
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── s3.tf
│   │   ├── lambda_ingestion.tf
│   │   ├── glue.tf
│   │   ├── step_functions.tf
│   │   ├── iam.tf
│   │   ├── cloudwatch.tf
│   │   └── eventbridge.tf
│   └── terragrunt/
│       ├── terragrunt.hcl
│       └── dev/
│           └── terragrunt.hcl
├── src/
│   ├── lambda/
│   │   ├── api_ingestion/
│   │   │   ├── lambda_handler.py
│   │   │   ├── api_client.py
│   │   │   ├── requirements.txt
│   │   │   └── tests/
│   │   │       └── test_handler.py
│   │   └── glue_trigger/
│   │       └── lambda_handler.py
│   └── glue/
│       ├── jobs/
│       │   ├── transform_job.py
│       │   └── validate_job.py
│       ├── scripts/
│       │   ├── data_quality.py
│       │   └── transformations.py
│       └── tests/
│           └── test_transformations.py
├── step_functions/
│   ├── state_machine.json
│   └── state_machine.asl.json
├── scripts/
│   ├── package_lambda.sh
│   ├── deploy.sh
│   ├── test_api.sh
│   ├── run_glue_local.sh
│   └── cleanup.sh
├── tests/
│   ├── integration/
│   │   └── test_end_to_end.py
│   └── sample_data/
│       └── sample_api_response.json
├── config/
│   ├── dev.yaml
│   ├── prod.yaml
│   └── glue_job_config.json
└── .github/
    └── workflows/
        └── ci-cd.yaml
```

## 🏗️ Architecture

```
┌─────────────┐
│ EventBridge │ Daily 9 AM UTC
│   Schedule  │
└──────┬──────┘
       │ Trigger
       ▼
┌─────────────────┐
│ Step Functions  │ Orchestrate workflow
│  State Machine  │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌──────────┐
│Lambda  │ │  Glue    │
│ API    │ │  Job     │
│Ingestion│ │Transform │
└───┬────┘ └────┬─────┘
    │           │
    ▼           ▼
┌────────────────────┐
│   S3 Buckets       │
│  - Raw             │
│  - Processed       │
│  - Curated         │
└────────┬───────────┘
         │
         ▼
    ┌────────┐
    │ Glue   │
    │Crawler │
    └───┬────┘
        │
        ▼
    ┌────────┐
    │ Athena │
    │ Query  │
    └────────┘
```

## 📚 Learning Objectives

By building this project, you'll learn:

1. **API Integration**: Fetching data from public APIs with Lambda
2. **Step Functions**: Orchestrating multi-step workflows
3. **AWS Glue**: Serverless Spark for data transformation
4. **Glue Crawler**: Automated schema discovery
5. **Athena**: SQL queries on S3 data
6. **EventBridge**: Scheduled triggers (cron expressions)
7. **Data Quality**: Validation and error handling
8. **Infrastructure as Code**: Terraform/Terragrunt patterns

## 🎯 Data Flow

1. **Extract**: Lambda fetches data from public API (e.g., OpenWeather, GitHub, CoinGecko)
2. **Raw Storage**: Store raw JSON in S3 `raw/` prefix with date partition
3. **Transform**: Glue job reads raw data, cleans, validates, and transforms
4. **Curated Storage**: Write Parquet files to S3 `curated/` with partitions
5. **Catalog**: Glue Crawler updates Data Catalog
6. **Query**: Athena allows SQL queries on the curated data

## 🚀 Getting Started

### Prerequisites

- AWS Account with Admin access
- AWS CLI configured
- Terraform >= 1.5
- Python 3.12
- Docker (for local Glue testing)

### Quick Start

```bash
1. Clone the repository

git clone <your-repo>
cd scheduled-etl-pipeline

2. Choose your API

Edit config/dev.yaml and set your API choice:
- openweather (weather data)
- github (repository stats)
- coingecko (cryptocurrency prices)

3. Package Lambda functions
./scripts/package_lambda.sh

4. Deploy infrastructure (terragrunt used to manage infrastructure)

cd infrastructure/terragrunt/dev
terragrunt init
terragrunt apply

5. Test the pipeline

cd ../../../
./scripts/test_api.sh

6. Trigger Step Function manually (first time)

aws stepfunctions start-execution \
  --state-machine-arn $(terragrunt output -raw step_function_arn) \
  --name "manual-test-$(date +%s)"

7. Query data in Athena
Go to AWS Console > Athena
Run: SELECT * FROM curated_data LIMIT 10;

```

## Step-by-Step Build Guide

### Phase 1: API Ingestion
- [ ] Create Lambda function to fetch API data
- [ ] Store raw JSON in S3 with date partitions
- [ ] Add error handling and retries
- [ ] Test with sample API

**Guide**: See `docs/API_GUIDE.md`

### Phase 2: Glue ETL
- [ ] Write Glue job to read raw JSON
- [ ] Transform data (clean, validate, enrich)
- [ ] Write Parquet to curated bucket
- [ ] Test locally with Docker

**Guide**: See `docs/GLUE_GUIDE.md`

### Phase 3: Orchestration
- [ ] Design Step Functions state machine
- [ ] Add error handling and retries
- [ ] Connect Lambda and Glue job
- [ ] Add success/failure notifications

**Guide**: See `docs/STEP_FUNCTIONS_GUIDE.md`

### Phase 4: Automation
- [ ] Add EventBridge schedule
- [ ] Configure Glue Crawler
- [ ] Set up Athena database
- [ ] Create CloudWatch dashboards

## 🧪 Testing

```bash
# Test Lambda locally
cd src/lambda/api_ingestion
python -m pytest tests/

# Test Glue job locally (requires Docker)
./scripts/run_glue_local.sh

# Integration test
python tests/integration/test_end_to_end.py
```

## Monitoring

- **CloudWatch Logs**: `/aws/lambda/api-ingestion`, `/aws-glue/jobs/transform-job`
- **Step Functions**: Execution history in AWS Console
- **Glue Job Metrics**: Duration, DPU hours, records processed
- **Cost Tracking**: Tagged resources in Cost Explorer

## Cost Estimate

**Daily run (assuming small dataset):**
- Lambda: ~$0.01/day
- Glue: ~$0.44/hour (only runs ~5 min) = ~$0.04/day
- S3: ~$0.02/day
- Step Functions: ~$0.0001/day
- **Total Estimate: ~$0.07/day or ~$2/month**

## Technologies

- **AWS Services**: Lambda, Glue, S3, Step Functions, EventBridge, Athena, CloudWatch
- **IaC**: Terraform, Terragrunt
- **Languages**: Python 3.12, PySpark
- **Testing**: pytest, moto (AWS mocking)

## Resources

- [AWS Glue Documentation](https://docs.aws.amazon.com/glue/)
- [Step Functions Tutorial](https://docs.aws.amazon.com/step-functions/)
- [PySpark Guide](https://spark.apache.org/docs/latest/api/python/)

## Contributing

This is a learning project. Feel free to:
- Add new API sources
- Improve data quality checks
- Add more transformation logic
- Enhance monitoring
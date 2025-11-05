# Architecture Deep Dive

## Overview

This ETL pipeline follows the **Medallion Architecture** pattern:
- **Bronze Layer** (Raw): Unprocessed data from API
- **Silver Layer** (Processed): Cleaned and validated
- **Gold Layer** (Curated): Business-ready analytics data

## Components Explained

### 1. EventBridge Scheduler

**What**: Managed cron service that triggers workflows on schedule
**Why**: Serverless, no EC2 needed, sub-minute precision
**When**: Runs daily at 9 AM UTC (configurable)

```python
# Cron expression: Daily at 9 AM UTC
schedule_expression = "cron(0 9 * * ? *)"
```

**Learning Points:**
- Cron syntax in AWS
- Event patterns vs schedules
- Timezone handling (always UTC)

---

### 2. Step Functions State Machine

**What**: Workflow orchestrator that coordinates Lambda and Glue
**Why**: Visual workflows, built-in error handling, parallel execution
**When**: Triggered by EventBridge

**State Machine Flow:**
```
Start
  → Invoke Lambda (API Ingestion)
  → Wait for completion
  → Check if data exists
    → Yes: Start Glue Job
      → Wait for Glue completion
      → Start Glue Crawler
      → Send success notification
    → No: Send failure notification
  → End
```

**Learning Points:**
- State machine patterns (sequential, parallel, choice)
- Error handling with retries and catch blocks
- Passing data between states
- Best practices for long-running jobs

---

### 3. Lambda: API Ingestion

**What**: Serverless function that fetches data from external API
**Why**: Event-driven, auto-scales, pay per request
**Runtime**: Python 3.12

**Responsibilities:**
1. Authenticate with API (if needed)
2. Fetch data with pagination
3. Validate response
4. Write raw JSON to S3 (bronze layer)
5. Return metadata to Step Functions

**Code Structure:**
```python
def handler(event, context):
    # 1. Get API config from event
    # 2. Make API request
    # 3. Handle errors/retries
    # 4. Write to S3
    # 5. Return success/failure
```

**Learning Points:**
- Handling API rate limits
- Retry strategies with exponential backoff
- Error handling patterns
- S3 SDK best practices
- Environment variable management

---

### 4. AWS Glue ETL Job

**What**: Managed Apache Spark job for data transformation
**Why**: Serverless Spark, auto-scaling, columnar format support
**Language**: PySpark

**Responsibilities:**
1. Read raw JSON from S3 (bronze)
2. Schema validation
3. Data cleaning (nulls, duplicates, formats)
4. Business transformations
5. Write Parquet to S3 (gold) with partitions

**Code Structure:**
```python
from pyspark.sql import SparkSession
from awsglue.context import GlueContext

# 1. Initialise Glue context
# 2. Read source data
# 3. Apply transformations
# 4. Write to curated
```

**Learning Points:**
- PySpark DataFrame operations
- Glue-specific APIs (GlueContext, DynamicFrame)
- Partitioning strategies
- Parquet optimisation (compression, column pruning)
- Glue job parameters

---

### 5. Glue Crawler

**What**: Service that scans S3 and infers schema
**Why**: Auto-detects schema changes, updates Data Catalog
**When**: Runs after Glue job completes

**Responsibilities:**
1. Scan S3 prefix (curated/)
2. Infer schema from Parquet files
3. Create/update table in Glue Catalog
4. Detect partitions

**Learning Points:**
- Glue Data Catalog concepts
- Schema evolution handling
- Partition projection
- Crawler exclusion patterns

---

### 6. Amazon Athena

**What**: Serverless SQL query engine
**Why**: Query S3 data without loading into database
**Cost**: Pay per query ($5 per TB scanned)

**Usage:**
```sql
-- Query curated data
SELECT * FROM curated_data
WHERE year = 2025 AND month = 11
LIMIT 100;
```

**Learning Points:**
- Athena SQL dialect (Presto)
- Partitioning for cost optimisation
- Query optimisation techniques
- CTAS (Create Table As Select)

---

## Data Flow Diagram

```sh
┌──────────────────────────────────────────────────────────────┐
│                     EventBridge Schedule                     │
│                   (Daily 9 AM UTC)                           │
└─────────────────────────┬────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────────┐
│                   Step Functions State Machine               │
│                                                              │
│  [Start] → [Lambda] → [Choice] → [Glue] → [Crawler] → [End]  │
│              ▲                      ▲                        │
│              │                      │                        │
│           [Error]               [Error]                      │
│              │                      │                        │
│           [SNS]                  [SNS]                       │
└─────────────────────────┬────────────────────────────────────┘
                          │
          ┌───────────────┴───────────────┐
          ▼                               ▼
┌──────────────────┐           ┌──────────────────┐
│  Lambda Function │           │   Glue ETL Job   │
│  (API Ingestion) │           │  (Transform)     │
└────────┬─────────┘           └─────────┬────────┘
         │                               │
         ▼                               ▼
┌──────────────────────────────────────────────────────────────┐
│                          S3 Buckets                          │
│                                                              │
│  raw/                 processed/              curated/       │
│  └─ YYYY/MM/DD/      └─ YYYY/MM/DD/         └─ year=YYYY/    │
│     data.json           data_clean.json        month=MM/     │
│                                                 day=DD/      │
│                                                 data.parquet │
└─────────────────────────┬────────────────────────────────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │  Glue Crawler   │
                 └────────┬────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │  Glue Catalog   │
                 │  (Metadata)     │
                 └────────┬────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │     Athena      │
                 │   (SQL Query)   │
                 └─────────────────┘
```

---

## Error Handling Strategy

### Lambda Errors
- **API Failure**: Retry 3 times with exponential backoff
- **S3 Write Failure**: Log and fail (will retry via Step Functions)
- **Timeout**: Set to 5 minutes

### Glue Job Errors
- **Data Quality**: Skip bad records, log to CloudWatch
- **Job Failure**: Retry 2 times via Step Functions
- **Timeout**: Set to 30 minutes

### Step Functions Errors
- **Task Failed**: Catch error, send SNS notification
- **Timeout**: Set to 60 minutes total


## Security Architecture

### IAM Roles
1. **Lambda Execution Role**
   - S3: Read/Write to raw bucket
   - Logs: Write to CloudWatch
   - Secrets Manager: Read API keys

2. **Glue Job Role**
   - S3: Read raw, Write curated
   - Glue Catalog: Update tables
   - Logs: Write to CloudWatch

3. **Step Functions Role**
   - Lambda: Invoke function
   - Glue: Start job
   - SNS: Publish messages

### S3 Bucket Policies
- Server-side encryption (SSE-S3)
- Versioning enabled
- Lifecycle rules (delete raw after 30 days)


## Scalability Considerations

### Lambda
- **Concurrent executions**: 10 (prevents API rate limit)
- **Memory**: 512 MB (adjust based on API response size)
- **Timeout**: 5 minutes

### Glue
- **DPU (Data Processing Units)**: 2 (start small, scale up)
- **Max capacity**: 10 DPU (cost control)
- **Worker type**: G.1X (general purpose)

### S3
- **Partitioning**: By date (`year=YYYY/month=MM/day=DD`)
- **File size**: Target 128 MB per Parquet file
- **Compaction**: Weekly job to merge small files


## Cost Optimisation

1. **Use S3 Intelligent-Tiering** for older data
2. **Lifecycle policies** to delete raw data after 30 days
3. **Glue bookmarks** to process only new data
4. **Athena partitions** to reduce data scanned
5. **Compress Parquet** with Snappy (balance of speed/size)


## Monitoring & Alerts

### CloudWatch Metrics
- Lambda: Duration, Errors, Throttles
- Glue: DPU-Hours, Records Processed
- Step Functions: Execution Status
- S3: Object Count, Bucket Size

### Alarms
- Lambda error rate > 5%
- Glue job duration > 30 minutes
- Step Function failures

### Dashboards
- Daily execution trends
- Data quality metrics
- Cost per execution

---

## Next Steps

After building this, consider:
1. **Add data quality checks** (Great Expectations)
2. **Implement SCD Type 2** (slowly changing dimensions)
3. **Add QuickSight dashboard** for visualisation
4. **Implement CDC** with DynamoDB Streams
5. **Add machine learning** with SageMaker

---

**Key Takeaway**: This architecture is production-ready, cost-effective, and teaches you real-world AWS patterns used in 90% of data engineering roles.
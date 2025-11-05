# API Ingestion Guide

## Overview

The Lambda function fetches data from external APIs and stores it in S3. This guide helps in understanding and building the ingestion component.

## APIs to use for raw data

### 1. OpenWeather API (Recommended for Learning)

**Why**: Free tier, simple, real-world use case

```python
# API Endpoint
url = "https://api.openweathermap.org/data/2.5/weather"
params = {
    "q": "London",
    "appid": "YOUR_API_KEY",
    "units": "metric"
}
```

**Sign up**: https://openweathermap.org/api
**Free tier**: 1,000 calls/day

**Sample Response**:
```json
{
  "coord": {"lon": -0.1257, "lat": 51.5085},
  "weather": [{"id": 800, "main": "Clear", "description": "clear sky"}],
  "main": {
    "temp": 15.5,
    "feels_like": 14.2,
    "pressure": 1013,
    "humidity": 72
  },
  "dt": 1699545600,
  "name": "London"
}
```

---

### 2. CoinGecko API (Cryptocurrency)

**Why**: No API key needed, JSON response

```python
url = "https://api.coingecko.com/api/v3/simple/price"
params = {
    "ids": "bitcoin,ethereum",
    "vs_currencies": "usd,eur",
    "include_24hr_change": "true"
}
```

**Sample Response**:
```json
{
  "bitcoin": {
    "usd": 35000,
    "eur": 33000,
    "usd_24h_change": 2.5
  }
}
```

---

### 3. GitHub API (Repository Stats)

**Why**: Learn pagination, rate limiting

```python
url = "https://api.github.com/repos/apache/spark"
headers = {"Authorization": "token YOUR_TOKEN"}
```

**Sample Response**:
```json
{
  "name": "spark",
  "stargazers_count": 35000,
  "forks_count": 28000,
  "open_issues_count": 1200
}
```

---

## Required Lambda Handler Structure

```python
import json
import boto3
import os
from datetime import datetime
from api_client import APIClient

def handler(event, context):
    """
    Ingest data from external APIs and store in S3
    
    Steps to implement:
    
    1. Parse input contract
       - Extract api_type (default: "openweather")
       - Extract params dict
       - Log context metadata (request_id, function_name)
    
    2. Initialize clients
       - Read RAW_BUCKET from environment (fail if missing)
       - Initialize APIClient(api_type)
       - Initialize boto3.client('s3')
    
    3. Fetch data from API
       - Call api_client.fetch(params)
       - Validate response structure for api_type
       - Handle retries and rate limits in client
    
    4. Build S3 key with partitions
       - Format: raw/year=YYYY/month=MM/day=DD/data_HHMMSS_<request_id>.json
       - Use UTC timestamp
       - Include unique suffix for idempotency
    
    5. Write to S3
       - Put object with Content-Type=application/json
       - Enable server-side encryption
       - Capture ETag from response
    
    6. Return structured response
       - statusCode: 200
       - body: {message, s3_bucket, s3_key, record_count, timestamp}
       - Use ISO-8601 format for timestamp
    
    7. Handle errors
       - Log structured errors with level, api_type, error_code
       - Emit CloudWatch metrics (ingestion_success, ingestion_failure)
       - Raise exception with clear message
    
    8. Security considerations
       - Retrieve API keys from Secrets Manager
       - Never log sensitive values
       - Validate payload size before storing
    """
    pass
```

---

## API Client Implementation

```python
import requests
import os
import time
from typing import Dict, Any

class APIClient:
    """
    Generic API client with retry logic
    
    Implementation Steps:
    
    1. __init__(api_type)
       - Store api_type
       - Get API key from env: {API_TYPE}_API_KEY
       - Set base_url from _get_base_url()
    
    2. _get_base_url() -> str
       - Map api_type to URL:
         openweather → https://api.openweathermap.org/data/2.5
         coingecko → https://api.coingecko.com/api/v3
         github → https://api.github.com
       - Raise ValueError if not found
    
    3. fetch(params) -> dict
       - Build URL (openweather: /weather, coingecko: /simple/price, github: /repos/{repo})
       - Add API key to params if needed (openweather)
       - Set headers (github needs Authorization)
       - Call _retry_with_backoff(() => requests.get(url, params, headers, timeout=30))
       - Check status_code == 200
       - Return response.json()
    
    4. _retry_with_backoff(func, max_retries=3)
       - Loop max_retries times:
         * Try func()
         * On 429: sleep Retry-After seconds
         * On error: sleep 2^attempt seconds
       - Raise if all retries fail
    """
    
    def __init__(self, api_type: str):
        pass
        
    def _get_base_url(self) -> str:
        pass
    
    def fetch(self, params: Dict[str, Any]) -> Dict[str, Any]:
        pass
    
    def _retry_with_backoff(self, func, max_retries=3):
        pass
```
---

## Error Handling Patterns

### 1. API Rate Limiting

```python
def handle_rate_limit(response):
    """Handle 429 Too Many Requests"""
    if response.status_code == 429:
        retry_after = int(response.headers.get('Retry-After', 60))
        print(f"Rate limited. Waiting {retry_after}s...")
        time.sleep(retry_after)
        return True
    return False
```

### 2. Timeout Handling

```python
try:
    response = requests.get(url, timeout=30)
except requests.exceptions.Timeout:
    print("Request timed out. Retrying...")
    # Retry logic here
```

### 3. Invalid Response

```python
def validate_response(data):
    """Validate API response structure"""
    if not data:
        raise ValueError("Empty response from API")
    
    # Add specific validation based on API
    if api_type == 'openweather':
        if 'main' not in data:
            raise ValueError("Invalid weather data structure")
```

---

## Testing Locally

```bash
# 1. Set environment variables
export RAW_BUCKET=my-raw-bucket
export OPENWEATHER_API_KEY=your_key_here

# 2. Create test event
cat > test_event.json <<EOF
{
  "api_type": "openweather",
  "params": {
    "q": "London",
    "units": "metric"
  }
}
EOF

# 3. Run handler locally
cd src/lambda/api_ingestion
python lambda_handler.py
```

---

## Unit Tests

```python
# src/lambda/api_ingestion/tests/test_handler.py
import pytest
import json
from unittest.mock import patch, MagicMock
from lambda_handler import handler

@pytest.fixture
def lambda_context():
    """Mock Lambda context"""
    context = MagicMock()
    context.function_name = "api-ingestion"
    context.memory_limit_in_mb = 512
    return context

@pytest.fixture
def api_event():
    """Sample event from Step Functions"""
    return {
        "api_type": "openweather",
        "params": {"q": "London"}
    }

def test_successful_ingestion(lambda_context, api_event):
    """Test successful API call and S3 write"""
    # TODO: Mock API response
    # TODO: Mock S3 client
    # TODO: Call handler
    # TODO: Assert response structure
    pass

def test_api_failure(lambda_context, api_event):
    """Test handling of API failure"""
    # TODO: Mock failed API response
    # TODO: Assert error handling
    pass

def test_rate_limiting(lambda_context, api_event):
    """Test rate limit handling"""
    # TODO: Mock 429 response
    # TODO: Assert retry logic
    pass
```

Run tests:
```bash
cd src/lambda/api_ingestion
python -m pytest tests/ -v
```

---

## Deployment

```bash
# Package Lambda function
cd scripts
./package_lambda.sh

# Deploy with Terraform
cd infrastructure/terragrunt/dev
terragrunt apply -target=module.lambda_ingestion
```

---

## Monitoring

### CloudWatch Logs

```bash
# Tail Lambda logs
aws logs tail /aws/lambda/api-ingestion --follow

# Filter for errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/api-ingestion \
  --filter-pattern "ERROR"
```

### Metrics to Monitor

1. **Invocation Count**: Should match schedule (once per day)
2. **Duration**: Typically < 10 seconds
3. **Errors**: Should be 0
4. **Throttles**: Should be 0

---

## Best Practices

1. **API Keys**: Store in AWS Secrets Manager, not environment variables
2. **Retries**: Implement exponential backoff
3. **Logging**: Use structured logging (JSON format)
4. **Timeouts**: Set appropriate timeouts (Lambda 5 min, HTTP 30s)
5. **Idempotency**: Use unique S3 keys to avoid overwrites


## Next Steps

After completing API ingestion:
1. ✅ Test with multiple API types
2. ✅ Add data validation
3. ✅ Implement pagination for large responses
4. ✅ Move to Glue transformation (see GLUE_GUIDE.md)

---

**Learning Checkpoint**: You should now understand:
- How to call external APIs from Lambda
- Error handling and retry strategies
- Writing data to S3 with partitions
- Testing Lambda functions locally
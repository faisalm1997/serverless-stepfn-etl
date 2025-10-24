# serverless-stepfn-etl

Purpose: A complete serverless pipeline with Step Functions orchestrating Lambda and Glue to ingest API data into S3, transform it, and catalog via Glue for Athena queries.

## Repo Structure

```sh
serverless-stepfn-etl/
├── infrastructure/
│ ├── terraform/
│ │ ├── modules/
│ │ │ ├── stepfunctions/
│ │ │ ├── lambda/
│ │ │ ├── glue/
│ │ │ ├── s3/
│ │ │ ├── cloudwatch/
│ │ │ └── iam/
│ │ └── envs/
│ └── terragrunt/
│ ├── dev/
│ └── prod/
├── src/
│ ├── lambda/
│ │ └── ingest_api.py
│ └── glue_jobs/
│ └── transform_to_parquet.py
├── stepfunctions/
│ └── state_machine_definition.asl.json
├── config/
│ ├── api_config.json
│ └── crawler_settings.json
├── scripts/
│ ├── deploy_stepfn.sh
│ ├── test_lambda_local.sh
│ └── trigger_pipeline.sh
├── tests/
│ ├── test_ingest_lambda.py
│ └── test_glue_transform.py
├── .github/
│ ├── github-actions.yaml
│ └── sam-buildspec.yml
├── docs/
│ ├── architecture.png
│ ├── stepfunction_flow.md
│ └── troubleshooting.md
└── README.md
```


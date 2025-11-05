# Development environment configuration

include "root" {
  path = find_in_parent_folders()
}

# Load environment variables
locals {
  environment = "dev"
  aws_region  = "us-east-1"
}

# Environment-specific inputs

inputs = {

    TODO: Include environment, project_name, lambda timeout/memory_size, glue worker_type, number_of_workers, timeout,
    schedule_expression, schedule_enabled, api_type, s3_lifecycle_raw_days, s3_lifecycle_curated_days, cloudwatch_log_retention_days, enable_cloudwatch_alarms, alert_email

    common_tags = {
        environment, CostCenter, owner
    }
}
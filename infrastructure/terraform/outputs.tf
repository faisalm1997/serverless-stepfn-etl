# TODO: Add outputs for scheduled ETL pipeline config
# Outputs for all bucket names, lambda_function_name, state_machine_arn, glue_database, glue_job_name, crawler_name

output "raw_bucket_name" {
  description = "Name of the raw S3 bucket"
  value       = aws_s3_bucket.raw_bucket.bucket
}

output "curated_bucket_name" {
  description = "Name of the curated S3 bucket"
  value       = aws_s3_bucket.curated_bucket.bucket
}

output "scripts_bucket_name" {
  description = "Name of the scripts S3 bucket"
  value       = aws_s3_bucket.scripts_bucket.bucket
}

output "glue_database_name" {
  description = "Name of the Glue database"
  value       = aws_glue_catalog_database.glue_database.name
}

output "glue_job_name" {
  description = "Name of the Glue ETL job"
  value       = aws_glue_job.glue_etl_job.name
}

output "glue_crawler_name" {
  description = "Name of the Glue crawler"
  value       = aws_glue_crawler.glue_crawler.name
}

output "state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.etl_state_machine.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.lambda_ingestion.function_name
}
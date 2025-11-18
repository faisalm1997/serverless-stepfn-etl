variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)."
  type        = string
}

variable "raw_bucket_name" {
  description = "The name of the S3 bucket for raw data."
  type        = string
}

variable "curated_bucket_name" {
  description = "The name of the S3 bucket for curated data."
  type        = string
}

variable "scripts_bucket_name" {
  description = "The name of the S3 bucket for Glue scripts."
  type        = string
}

variable "common_tags" {
  description = "A map of common tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "api_endpoint" {
  description = "The API endpoint URL for data ingestion."
  type        = string
}

variable "alerts_email" {
  description = "The email address to receive alerts."
  type        = string
}

variable "glue_worker_type" {
  description = "The type of worker to use for the Glue job."
  type        = string
  default     = "G.1X"
}

variable "glue_number_of_workers" {
  description = "The number of workers to allocate for the Glue job."
  type        = number
  default     = 2
}

variable "glue_job_timeout" {
  description = "The timeout in minutes for the Glue job."
  type        = number
  default     = 30
}

variable "glue_version" {
  description = "The Glue version to use for the Glue job."
  type        = string
  default     = "3.0"
}

variable "lambda_function_name" {
  description = "The name of the Lambda function."
  type        = string
  default     = "etl_lambda"
}
# Package Lambda code automatically

data "lambda_package" "lambda_ingestion_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../src/lambda/ingestion"
  output_path = "${path.module}/../../src/lambda/lambda_ingestion.zip"
}

# Lambda function

resource "aws_lambda_function" "lambda_ingestion" {
  function_name    = "${var.project_name}-${var.environment}-lambda-ingestion"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "ingestion_handler.lambda_handler"
  runtime          = "python3.12"
  filename         = data.lambda_package.lambda_ingestion_zip.output_path
  source_code_hash = data.lambda_package.lambda_ingestion_zip.output_base64sha256

  environment {
    variables = {
      RAW_BUCKET_NAME = aws_s3_bucket.raw_bucket.bucket
      #   API_ENDPOINT    = var.api_endpoint
    }
  }

  timeout     = 300
  memory_size = 512

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-lambda-ingestion"
  })
}
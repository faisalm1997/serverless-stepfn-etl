# IAM role for Lambda execution
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Lambda execution role
resource "aws_iam_role" "lambda_execution" {
  name               = "${var.lambda_function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = merge(var.common_tags, {
    Name = "${var.lambda_function_name}-role"
  })
}

# Lambda policy to allow s3 writes, cloudwatch logs 

resource "aws_iam_role_policy" "lambda_s3_cloudwatch_policy" {
  name = "lambda-s3-cloudwatch-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.raw_bucket.arn,
          "${aws_s3_bucket.raw_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:/aws/lambda/*"
      }
    ]
  })
}

# Create glue execution role, needs S3 read/write, Glue catalog access


# Create step function execution role, needs lambda invoke/glue start job permissions
# Create IAM role for eventbridge to invoke step functions
# Create IAM policy to allow starting Step Functions execution


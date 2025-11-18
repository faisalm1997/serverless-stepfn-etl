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
  name               = "${var.lambda_function_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = merge(var.common_tags, {
    Name = "${var.lambda_function_name}-lambda-role"
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
          "${aws_s3_bucket.raw_bucket.arn}/*",
          aws_s3_bucket.curated_bucket.arn,
          "${aws_s3_bucket.curated_bucket.arn}/*",
          aws_s3_bucket.scripts_bucket.arn,
          "${aws_s3_bucket.scripts_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
      }
    ]
  })
}

# Create glue execution role, needs S3 read/write, Glue catalog access

data "aws_iam_policy_document" "glue_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "glue_execution" {
  name               = "${var.project_name}-${var.environment}-glue-role"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-glue-role"
  })
}

resource "aws_iam_role_policy" "glue_s3_catalog_policy" {
  name = "glue-s3-catalog-policy"
  role = aws_iam_role.glue_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.raw_bucket.arn,
          "${aws_s3_bucket.raw_bucket.arn}/*",
          aws_s3_bucket.curated_bucket.arn,
          "${aws_s3_bucket.curated_bucket.arn}/*",
          aws_s3_bucket.scripts_bucket.arn,
          "${aws_s3_bucket.scripts_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:*"
        ]
        Resource = [
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:database/*",
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/*"
      }
    ]
  })
}

# Create step function execution role, needs lambda invoke/glue start job permissions
data "aws_iam_policy_document" "stp_fn_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "stp_fn_execution" {
  name               = "${var.project_name}-${var.environment}-stepfn-role"
  assume_role_policy = data.aws_iam_policy_document.stp_fn_assume_role.json

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-stepfn-role"
  })
}

resource "aws_iam_role_policy" "stepfn_lambda_glue_policy" {
  name = "stepfn-lambda-glue-policy"
  role = aws_iam_role.stp_fn_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.etl_lambda.arn
      },
      {
        Effect = "Allow"
        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJobRuns",
          "glue:BatchStopJobRun"
        ]
        Resource = aws_glue_job.etl_glue_job.arn
      },
      {
        Effect = "Allow"
        Action = [
          "glue:StartCrawler",
          "glue:GetCrawler"
        ]
        Resource = [
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:crawler/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# Create IAM role for eventbridge to invoke step functions

data "aws_iam_policy_document" "eventbridge_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eventbridge_execution" {
  name               = "${var.project_name}-${var.environment}-eventbridge-role"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_assume_role.json

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-eventbridge-role"
  })
}

# Create eventbridge IAM policy to allow starting Step Functions execution

resource "aws_iam_role_policy" "eventbridge_stepfn_policy" {
  name = "eventbridge-stepfn-policy"
  role = aws_iam_role.eventbridge_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution"
        ]
        Resource = aws_sfn_state_machine.stepfn_etl.arn
      }
    ]
  })
}
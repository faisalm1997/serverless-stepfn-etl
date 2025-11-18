# CloudWatch Log Group for lambda function

resource "aws_cloudwatch_log_group" "lambda_ingestion_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_ingestion.function_name}"
  retention_in_days = 14

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-lambda-ingestion-log-group"
  })
}

# CloudWatch Metric Alarm for Lambda Duration Anomaly Detection

resource "aws_cloudwatch_metric_alarm" "lambda_duration_anomaly" {
  alarm_name          = "${var.project_name}-lambda-duration-anomaly"
  comparison_operator = "LessThanLowerOrGreaterThanUpperThreshold"
  evaluation_periods  = 2
  threshold_metric_id = "ad1"
  
  metric_query {
    id          = "m1"
    return_data = true
    metric {
      metric_name = "Duration"
      namespace   = "AWS/Lambda"
      period      = 300
      stat        = "Average"
      dimensions = {
        FunctionName = aws_lambda_function.lambda_ingestion.function_name
      }
    }
  }
  
  metric_query {
    id          = "ad1"
    expression  = "ANOMALY_DETECTION_BAND(m1, 2)"
  }
}

# sns topic for alerts

resource "aws_sns_topic" "alerts_topic" {
  name = "${var.project_name}-${var.environment}-alerts-topic"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-alerts-topic"
  })
}

# sns subscription

resource "aws_sns_topic_subscription" "alerts_email_subscription" {
  topic_arn = aws_sns_topic.alerts_topic.arn
  protocol  = "email"
  endpoint  = var.alerts_email
}

# cloudwatch alarm for lambda errors

resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-error-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1

  dimensions = {
    FunctionName = aws_lambda_function.lambda_ingestion.function_name
  }

  alarm_actions = [aws_sns_topic.alerts_topic.arn]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-lambda-error-alarm"
  })
}

# cloudwatch alarm for glue job failures

resource "aws_cloudwatch_metric_alarm" "glue_job_failure_alarm" {
  alarm_name          = "${var.project_name}-${var.environment}-glue-job-failure-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedJobs"
  namespace           = "AWS/Glue"
  period              = 300
  statistic           = "Sum"
  threshold           = 1

  dimensions = {
    JobName = aws_glue_job.glue_etl_job.name
  }

  alarm_actions = [aws_sns_topic.alerts_topic.arn]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-glue-job-failure-alarm"
  })
}

# cloudwatch alarm for step function execution failure

resource "aws_cloudwatch_metric_alarm" "step_function_failure_alarm" {
  alarm_name          = "${var.project_name}-${var.environment}-step-function-failure-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsFailed"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = 1

  dimensions = {
    StateMachineArn = aws_sfn_state_machine.etl_state_machine.arn
  }

  alarm_actions = [aws_sns_topic.alerts_topic.arn]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-step-function-failure-alarm"
  })
}
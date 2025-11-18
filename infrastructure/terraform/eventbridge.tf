# Cloudwatch event rule - schedule

resource "cloudwatch_event_rule" "daily_stepfn_trigger" {
  name                = "${var.project_name}-${var.environment}-daily-stepfn-trigger"
  description         = "Daily trigger for Step Functions ETL workflow"
  schedule_expression = "rate(1 day)"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-daily-stepfn-trigger"
  })
}

# Cloudwatch event target - step function 

resource "cloudwatch_event_target" "stepfn_target" {
  rule      = cloudwatch_event_rule.daily_stepfn_trigger.name
  target_id = "StepFunctionsETLWorkflow"
  arn       = aws_sfn_state_machine.etl_state_machine.arn
  role_arn  = aws_iam_role.eventbridge_execution.arn
}
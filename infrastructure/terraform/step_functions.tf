# TODO: Create Step Functions state machine
# Reference workflow definition which stored in ../../step_functions/workflow.json

resource "aws_sfn_state_machine" "etl_state_machine" {
  name     = "${var.project_name}-${var.environment}-etl-state-machine"
  role_arn = aws_iam_role.stp_fn_execution.arn

  definition = file("${path.module}/../../step_functions/workflow.json")

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-etl-state-machine"
  })
}

# Add Glue Crawler step after TransformData
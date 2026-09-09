resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/multienv-flow-logs"
  retention_in_days = 14
}

resource "aws_flow_log" "main" {
  vpc_id               = aws_vpc.main.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn
}

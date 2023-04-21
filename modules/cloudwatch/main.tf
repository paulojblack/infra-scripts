resource "aws_cloudwatch_log_group" "web_log_group" {
  name = "${var.project_name}_web"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "api_log_group" {
  name = "${var.project_name}-api"
  retention_in_days = 14
}
output "web_log_group_name" {
  description = "The name of the CloudWatch Log Group for the web service."
  value       = aws_cloudwatch_log_group.web_log_group.name
}

output "api_log_group_name" {
  description = "The name of the CloudWatch Log Group for the API service."
  value       = aws_cloudwatch_log_group.api_log_group.name
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "execution_role_arn" {
  description = "The ARN of the ECS execution role"
  type        = string
}

variable "task_role_arn" {
  description = "The ARN of the ECS task role"
  type        = string
}

variable "web_log_group_name" {
  description = "The name of the CloudWatch Log Group for the web service."
  type        = string
}

variable "api_log_group_name" {
  description = "The name of the CloudWatch Log Group for the API service."
  type        = string
}
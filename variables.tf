variable "aws_region" {
  description = "The AWS region where resources will be created"
  type        = string
  default     = "us-east-2"
}

variable "aws_account_id" {
  description = "The AWS region where resources will be created"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "172.31.0.0/16"
}

variable "public_subnet_cidr_blocks" {
  description = "A list of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["172.31.48.0/20", "172.31.64.0/20"]
}

### currently unused, hardcoded into cloudwatch module
variable "log_retention_in_days" {
  default = 14
}
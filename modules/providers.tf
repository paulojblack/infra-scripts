# providers.tf
provider "aws" {
  region = var.aws_region
}

locals {
  ui_image_url = "959320550138.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}-web:latest"
  api_image_url = "959320550138.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}-api:latest"
}



resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_execution_role.name
}
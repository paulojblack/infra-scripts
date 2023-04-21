provider "aws" {
  region = var.aws_region
}

locals {
  ui_image_url = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}-web:latest"
  api_image_url = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}-api:latest"
}

###
### PERMISSIONS CONFIGURATION
###

module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
}

###
### NETWORK CONFIGURATION
###

module "network" {
  source           = "./modules/network"
  project_name     = var.project_name
  vpc_cidr_block   = var.vpc_cidr_block
  public_subnet_cidr_blocks = var.public_subnet_cidr_blocks
}


###
### CLOUDWATCH LOG GROUPS
###

module "cloudwatch" {
  source           = "./modules/cloudwatch"
  project_name     = var.project_name
}

###
### ECS TASK DEFINITIONS
###

resource "aws_ecs_task_definition" "ecs_task_def" {
  family                = "${var.project_name}"
  requires_compatibilities = ["FARGATE"]
  network_mode         = "awsvpc"
  cpu                  = "1024"
  memory               = "2048"
  execution_role_arn   = module.iam.execution_role_arn
  task_role_arn        = module.iam.task_role_arn

  container_definitions = jsonencode([{
    name  = "${var.project_name}-web"
    image = local.ui_image_url
    essential = true
    portMappings = [
      {
        containerPort = 3000
        hostPort = 3000
      }
    ]
    logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group" = module.cloudwatch.web_log_group_name
          "awslogs-region" = var.aws_region
          "awslogs-stream-prefix" = "${var.project_name}-web"
        }
    }
  },
  {
    name  = "${var.project_name}-api"
    image = local.api_image_url
    essential = true
    portMappings = [
      {
        containerPort = 3001
        hostPort      = 3001
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group" = module.cloudwatch.api_log_group_name
        "awslogs-region" = var.aws_region
        "awslogs-stream-prefix" = "${var.project_name}-api"
      }
    }
  }])
}

###
### ECS/ECR SERVICE CONFIGURATION
###

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project_name}-ecs-cluster"
}

resource "aws_ecr_repository" "ui_srv" {
  name = "${var.project_name}-web"
}

resource "aws_ecr_repository" "api_srv" {
  name = "${var.project_name}-api"
}

resource "aws_ecs_service" "ecs_srv" {
  name            = var.project_name
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_def.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.network.public_subnets_ids
    security_groups  = [module.network.security_group_id]
    assign_public_ip = true
  }

  depends_on = [aws_ecs_task_definition.ecs_task_def]
}
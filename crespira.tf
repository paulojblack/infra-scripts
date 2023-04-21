provider "aws" {
  region = "us-east-2"
}

locals {
  ui_image_url = "959320550138.dkr.ecr.us-east-2.amazonaws.com/crespira-web:latest"
  api_image_url = "959320550138.dkr.ecr.us-east-2.amazonaws.com/crespira-api:latest"
}

resource "aws_ecs_cluster" "this" {
  name = "crespira-ecs-cluster"
}

resource "aws_ecr_repository" "ui_srv" {
  name = "crespira-web"
}

resource "aws_ecr_repository" "api_srv" {
  name = "crespira-api"
}

###
### NETWORK CONFIGURATION
###

resource "aws_vpc" "default_vpc" {
  cidr_block = "172.31.0.0/16"

  tags = {
    Name = "default_vpc"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id       = aws_vpc.default_vpc.id
  vpc_endpoint_type   = "Interface"
  service_name = "com.amazonaws.us-east-2.ecr.api"
}

resource "aws_subnet" "private" {
  count = 2

  cidr_block = "172.31.${48 + count.index * 16}.0/20"
  vpc_id     = aws_vpc.default_vpc.id
  tags = {
    Name = "crespira-private-subnet-${count.index + 1}"
  }
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.default_vpc.id
}

resource "aws_security_group_rule" "allow_all_in" {
  security_group_id = aws_security_group.allow_all.id

  type        = "ingress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_out" {
  security_group_id = aws_security_group.allow_all.id

  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_ecs_task_definition" "crespira" {
  family                = "crespira"
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
          "awslogs-group" = "${module.cloudwatch.web_log_group_name}"
          "awslogs-region" = "us-east-2"
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
        "awslogs-group" = "${module.cloudwatch.api_log_group_name}"
        "awslogs-region" = "us-east-2"
        "awslogs-stream-prefix" = "${var.project_name}-api"
      }
    }
  }])
}

###
### ECS SERVICE CONFIGURATION
###

resource "aws_ecs_service" "crespira" {
  name            = "crespira"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.crespira.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private.*.id
    security_groups  = [aws_security_group.allow_all.id]
    assign_public_ip = true
  }

  depends_on = [aws_ecs_task_definition.crespira]
}

###
### PERMISSIONS CONFIGURATION
###

# IAM module
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
}
### WIP, NOT SURE I WANT TO MODULARIZE THE ECS STUFF

###
### ECR REPOSITORIES
###
resource "aws_ecr_repository" "ui_srv" {
  name = "${var.project_name}-web"
}

resource "aws_ecr_repository" "api_srv" {
  name = "${var.project_name}-api"
}

###
### ECS TASK DEFINITIONS
###

resource "aws_ecs_cluster" "project_cluster" {
  name = var.project_name
}

resource "aws_ecs_task_definition" "project_task_definition" {
  family                = var.project_name
  requires_compatibilities = ["FARGATE"]
  network_mode         = "awsvpc"
  cpu                  = "1024"
  memory               = "2048"
  execution_role_arn   = var.execution_role_arn
  task_role_arn        = var.task_role_arn

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
          "awslogs-group" = var.web_log_group_name
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
        "awslogs-group" = "${var.project_name}-api"
        "awslogs-region" = "us-east-2"
        "awslogs-stream-prefix" = "crespira-api"
      }
    }
  }])
}

###
### ECS SERVICE CONFIGURATION
###

resource "aws_ecs_service" "crespira" {
  name            = "${var.project_name}"
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
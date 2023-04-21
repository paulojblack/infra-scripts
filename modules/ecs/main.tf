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
  name = var.cluster_name
}

resource "aws_ecs_task_definition" "project_task_definition" {
  family                = var.project_name
  requires_compatibilities = ["FARGATE"]
  network_mode         = "awsvpc"
  cpu                  = "1024"
  memory               = "2048"
  execution_role_arn   = module.iam.execution_role_arn
  task_role_arn        = module.iam.task_role_arn

  container_definitions = jsonencode([{
    name  = "crespira-web"
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
          "awslogs-group" = "crespira-web"
          "awslogs-region" = "us-east-2"
          "awslogs-stream-prefix" = "crespira-web"
        }
    }
  },
  {
    name  = "crespira-api"
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
        "awslogs-group" = "crespira-api"
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
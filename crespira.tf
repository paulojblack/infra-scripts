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
resource "aws_cloudwatch_log_group" "crespira_web_log_group" {
  name = "crespira-web"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "crespira_api_log_group" {
  name = "crespira-api"
  retention_in_days = 14
}

###
### ECS TASK DEFINITIONS
###

resource "aws_ecs_task_definition" "crespira" {
  family                = "crespira"
  requires_compatibilities = ["FARGATE"]
  network_mode         = "awsvpc"
  cpu                  = "256"
  memory               = "512"
  execution_role_arn   = aws_iam_role.ecs_execution_role.arn
  task_role_arn        = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name  = "crespira-web"
    image = local.ui_image_url
    essential = true
    portMappings = [
      {
        containerPort = 80
        hostPort      = 80
      }
    ]
    logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group" = "aws_cloudwatch_log_group.crespira_web_log_group.name"
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
        "awslogs-group" = "aws_cloudwatch_log_group.crespira_api_log_group.name"
        "awslogs-region" = "us-east-2"
        "awslogs-stream-prefix" = "crespira-api"
      }
    }
  }])
}
# resource "aws_ecs_task_definition" "crespira-web_task" {
#   family                = "crespira-web"
#   requires_compatibilities = ["FARGATE"]
#   network_mode         = "awsvpc"
#   cpu                  = "256"
#   memory               = "512"
#   execution_role_arn   = aws_iam_role.ecs_execution_role.arn
#   task_role_arn        = aws_iam_role.ecs_task_role.arn

#   container_definitions = jsonencode([{
#     name  = "crespira-web"
#     image = local.ui_image_url
#     essential = true
#     portMappings = [
#       {
#         containerPort = 80
#         hostPort      = 80
#       }
#     ]
#   }])
# }

# resource "aws_ecs_task_definition" "crespira-api_task" {
#   family                = "crespira-api"
#   requires_compatibilities = ["FARGATE"]
#   network_mode         = "awsvpc"
#   cpu                  = "256"
#   memory               = "512"
#   execution_role_arn   = aws_iam_role.ecs_execution_role.arn
#   task_role_arn        = aws_iam_role.ecs_task_role.arn

#   container_definitions = jsonencode([{
#     name  = "crespira-api"
#     image = local.api_image_url
#     essential = true
#     portMappings = [
#       {
#         containerPort = 3001
#         hostPort      = 3001
#       }
#     ]
#   }])
# }

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

# resource "aws_ecs_service" "crespira-api" {
#   name            = "crespira-api"
#   cluster         = aws_ecs_cluster.this.id
#   task_definition = aws_ecs_task_definition.crespira-api_task.arn
#   desired_count   = 1
#   launch_type     = "FARGATE"

#   network_configuration {
#     subnets          = aws_subnet.private.*.id
#     security_groups  = [aws_security_group.allow_all.id]
#     assign_public_ip = true
#   }

#   depends_on = [aws_ecs_task_definition.crespira-api_task]
# }


###
### PERMISSIONS CONFIGURATION
###

resource "aws_iam_role" "ecs_execution_role" {
  name               = "ecs_execution_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "ecs_task_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_ecr_readonly_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.ecs_execution_role.name
}

data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_execution_role.name
}

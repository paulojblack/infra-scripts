resource "aws_ecs_cluster" "project_cluster" {
  name = var.cluster_name
}

resource "aws_ecs_task_definition" "project_task_definition" {
  family                = var.task_definition_family
  requires_compatibilities = ["FARGATE"]
  network_mode         = "awsvpc"
  cpu                  = var.task_definition_cpu
  memory               = var.task_definition_memory
  execution_role_arn   = var.execution_role_arn
  task_role_arn        = var.task_role_arn

  container_definitions = jsonencode(var.container_definitions)
}

resource "aws_ecs_service" "project_service" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.project_cluster.id
  task_definition = aws_ecs_task_definition.project_task_definition.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets
    security_groups  = var.security_groups
    assign_public_ip = var.assign_public_ip
  }
}

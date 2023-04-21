data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.project_name}_ecs_task_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

### Execution role and its required policies
resource "aws_iam_role" "ecs_execution_role" {
  name               = "${var.project_name}_ecs_execution_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

# resource "aws_iam_policy" "ecs_execution_logs_policy" {
#   name        = "${var.project_name}_ecs_execution_logs_policy"
#   description = "Policy to allow ECS execution role to create log streams and put log events in CloudWatch Logs"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents",
#           "logs:DescribeLogStreams",
#         ]
#         Effect   = "Allow"
#         Resource = ["arn:aws:logs:*:*:log-group:${var.project_name}-web:*", "arn:aws:logs:*:*:log-group:${var.project_name}-api:*"]
#       }
#     ]
#   })
# }

resource "aws_iam_role_policy_attachment" "ecs_ecr_readonly_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.ecs_execution_role.name
}

resource "aws_iam_role_policy_attachment" "ecs_ecr_aws_execution_policy_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_execution_role.name
}

# resource "aws_iam_role_policy_attachment" "ecs_execution_logs_policy_attach" {
#   policy_arn = aws_iam_policy.ecs_execution_logs_policy.arn
#   role       = aws_iam_role.ecs_execution_role.name
# }
# Fargate stack deployment
The ultimate goal of this stack is to deploy all infra needed to host a Dockerized UI and API + Postgres RDS (not yet implemented) from an empty AWS account, including all network, roles and peripheral resources.

This is a learning exercise and probably sucks in several ways that I am unaware of.

# How to use
Locally:
1) `tf plan`
2) Verify everything looks good
3) `tf apply`

When starting from scratch, I suspect this will throw errors if you do not push any Docker images to the created ECR repositories before executing the portions of the config that rely on the existence of a Docker image in the specified repos.
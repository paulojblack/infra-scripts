# How to use
Locally:
1) `tf plan`
2) Verify everything looks good
3) `tf apply`

When starting from scratch, I suspect this will throw errors if you do not push any Docker images to the created ECR repositories before executing the portions of the config that rely on the existence of a Docker image in the specified repos.
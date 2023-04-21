# TODO: change the naming here to public as these seem to be created with IGW by default (desirable)
module "private_subnets" {
  source = "terraform-aws-modules/vpc/aws//modules/private-subnets"

  vpc_id = aws_vpc.default_vpc.id

  private_subnet_cidr_blocks = var.private_subnet_cidr_blocks
  private_subnet_tags = {
    "Name" = "${var.project_name}-private-subnet-${count.index + 1}"
  }
}
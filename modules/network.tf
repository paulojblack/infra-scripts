resource "aws_vpc" "default_vpc" {
  cidr_block = "172.31.0.0/16"

  tags = {
    Name = "default_vpc"
  }
}

## TODO REMOVE ME!
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id       = aws_vpc.default_vpc.id
  vpc_endpoint_type   = "Interface"
  service_name = "com.amazonaws.us-east-2.ecr.api"
}

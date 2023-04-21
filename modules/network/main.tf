resource "aws_vpc" "default_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "default_vpc"
  }
}

# TODO: change the naming here to public as these seem to be created with IGW by default (desirable)
resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_cidr_blocks)

  vpc_id                  = aws_vpc.default_vpc.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  tags = {
    "Name" = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}


###
### SECURITY GROUP CONFIGURATION
###
resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.default_vpc.id

#   lifecycle {
#     prevent_destroy = true
#   }
}

resource "aws_security_group_rule" "allow_all_in" {
  security_group_id = aws_security_group.allow_all.id

  type        = "ingress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

#   lifecycle {
#     prevent_destroy = true
#   }
}

resource "aws_security_group_rule" "allow_all_out" {
  security_group_id = aws_security_group.allow_all.id

  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

#   lifecycle {
#     prevent_destroy = true
#   }
}

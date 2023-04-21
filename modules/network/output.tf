output "vpc_id" {
  value = aws_vpc.default_vpc.id
}

output "public_subnets_ids" {
  value = aws_subnet.public_subnets.*.id
}

output "security_group_id" {
  value = aws_security_group.allow_all.id
}
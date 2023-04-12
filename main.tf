resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = merge(var.tags, {Name = "${var.env}-vpc"})
}
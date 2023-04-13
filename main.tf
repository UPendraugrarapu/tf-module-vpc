resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = merge(
    var.tags, 
    {Name = "${var.env}-vpc"}
    )
}

#public subnets

resource "aws_subnet" "public_subnets" {
  vpc_id = aws_vpc.main.id
   
  for_each = var.public_subnets 
  cidr_block = each.value["cidr_block"]
  availability_zone = each.value["availability_zone"]
  tags = merge(
    var.tags, 
    {Name = "${var.env}-${each.value["name"]}"}
    )

}
#Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags, 
    {Name = "${var.env}-igw"}
    )
}
#NAT gateway
resource "aws_eip" "nat" {
      for_each = var.public_subnets
      vpc      = true
}
resource "aws_nat_gateway" "nat-gateways" {
  for_each = var.public_subnets
  allocation_id = aws_eip.nat[each.value["name"]].id 
  subnet_id     = aws_subnet.public_subnets[each.value["name"]].id

  tags = merge(
    var.tags, 
    {Name = "${var.env}-${each.value["name"]}"}
    )
}

#public route table
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  for_each = var.public_subnets
  tags = merge(
    var.tags, 
    {Name = "${var.env}-${each.value["name"]}"}
    )

}
# route table association with public subnets

resource "aws_route_table_association" "public-association" {
  for_each = var.public_subnets
  subnet_id      = lookup(lookup(aws_subnet.public_subnets, each.value["name"], null), "id", null)
  route_table_id = aws_route_table.public-route-table[each.value["name"]].id
}

#private subnets

resource "aws_subnet" "private_subnets" {
  vpc_id = aws_vpc.main.id
       
  for_each = var.private_subnets 
  cidr_block = each.value["cidr_block"]
  availability_zone = each.value["availability_zone"]
  tags = merge(
    var.tags, 
    {Name = "${var.env}-${each.value["name"]}"}
    )

}


#private route table
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.main.id

  for_each = var.private_subnets
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gateways["public-${split("-", each.value["name"])[1]}"].id
    #availabilty_zone taken reference from public subnets of natgw
  }
   tags = merge(
    var.tags, 
    {Name = "${var.env}-${each.value["name"]}"}
    )

}
# route table association with private subnets

resource "aws_route_table_association" "private-association" {
  for_each = var.private_subnets
  subnet_id      = lookup(lookup(aws_subnet.private_subnets, each.value["name"], null), "id", null)
  route_table_id = aws_route_table.private-route-table[each.value["name"]].id
}


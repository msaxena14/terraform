# creating public route table by defining path to internet via igw
resource "aws_route_table" "public-rt" {
    vpc_id = var.vpc_id
 
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = var.igw_id
    }
 
    tags = {
        Name = "${var.project}-${var.environment}-Public-Route-Table"
    }
}

# associating all the public subnets to the public-rt
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_ids)
  subnet_id      = var.public_subnet_ids[count.index]
  route_table_id = aws_route_table.public-rt.id
}

# creating private route table by defining path to internet via nat-gateway
resource "aws_route_table" "private-rt" {
    vpc_id = var.vpc_id
 
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = var.nat_gateway_id
    }
 
    tags = {
        Name = "${var.project}-${var.environment}-Private-Route-Table"
    }
}

# associating all the private subnets to the private-rt
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_ids)
  subnet_id      = var.private_subnet_ids[count.index]
  route_table_id = aws_route_table.private-rt.id
}
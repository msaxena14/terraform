resource "aws_nat_gateway" "nat" {
  allocation_id = var.eip_id
  subnet_id     = var.public_subnet[0]

  tags = {
    Name = "${var.project}-${var.environment}-nat-gw"
  }
}
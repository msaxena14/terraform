provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Team        = var.team
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  # both are required for a private-only EKS endpoint to resolve inside the VPC
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-${var.environment}-vpc"
  }
}

# creating Elastic IP for NAT-Gateway (placed in a public subnet, serves pvt-sbnt egress)
resource "aws_eip" "eip" {
  domain = "vpc"

  tags = {
    Name = "${var.project}-${var.environment}-eip"
  }
}

# calling public subnet module
module "public-subnet" {
  source = "./modules/public-subnet"

  vpc_id              = aws_vpc.main.id
  public_subnet_cidrs = var.public_subnet_cidrs
  azs                 = var.azs
  project             = var.project
  environment         = var.environment
}

# calling private subnet module
module "private-subnet" {
  source = "./modules/private-subnet"

  vpc_id               = aws_vpc.main.id
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
  project              = var.project
  environment          = var.environment
}

# calling the internet-gateway module
module "internet-gateway" {
  source      = "./modules/internet-gateway"
  vpc_id      = aws_vpc.main.id
  project     = var.project
  environment = var.environment
}

# calling nat-gateway module with passing elaticip
module "nat-gateway" {
  source        = "./modules/nat-gateway"
  public_subnet = module.public-subnet.subnet_id
  eip_id        = aws_eip.eip.id
  project       = var.project
  environment   = var.environment

  # NAT gateway needs the IGW attached to the VPC first
  depends_on = [module.internet-gateway]
}

# calling route-table module
module "route-table" {
  source             = "./modules/route-table"
  vpc_id             = aws_vpc.main.id
  public_subnet_ids  = module.public-subnet.subnet_id
  private_subnet_ids = module.private-subnet.subnet_id
  igw_id             = module.internet-gateway.igw_id
  nat_gateway_id     = module.nat-gateway.nat_gateway_id
  project            = var.project
  environment        = var.environment
}
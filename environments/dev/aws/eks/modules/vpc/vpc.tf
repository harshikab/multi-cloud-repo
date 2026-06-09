resource "aws_vpc" "eks_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(var.common_tags, {
    Name = "eks-vpc"
  })
}

resource "aws_subnet" "public" {
  count                   = length(var.vpc_cidr_public_subnet)
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.vpc_cidr_public_subnet[count.index]
  map_public_ip_on_launch = true
  tags                    = merge(var.common_tags, { Name = "eks-public-subnet-${count.index + 1}" })
}

resource "aws_subnet" "private" {
  count                   = length(var.vpc_cidr_private_subnet)
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.vpc_cidr_private_subnet[count.index]
  map_public_ip_on_launch = false
  tags                    = merge(var.common_tags, { Name = "eks-private-subnet-${count.index + 1}" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags   = merge(var.common_tags, { Name = "eks-igw" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.eks_vpc.id
  tags   = merge(var.common_tags, { Name = "eks-public-rt" })

}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.vpc_cidr_public_subnet)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway and Elastic IP can be added here if private subnets need internet access
resource "aws_eip" "nat" {
  domain = "vpc"
  count = var.enable_gateway ? (var.single_nat_gateway ? 1 : length(var.vpc_cidr_private_subnet)) : 0 
   
  tags = merge(var.common_tags, { Name = "eks-nat-eip" })
  depends_on = [aws_internet_gateway.igw]
}

# Private route table and associations can be added here if needed, for example to route through a NAT Gateway

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.eks_vpc.id
  tags   = merge(var.common_tags, { Name = "eks-private-rt" })
}

resource "aws_nat_gateway" "nat" {
  count         = var.enable_gateway ? (var.single_nat_gateway ? 1 : length(var.vpc_cidr_private_subnet)) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id # NAT Gateway must be in a public subnet

  tags = merge(var.common_tags, { Name = "eks-nat-gateway-${count.index + 1}" })
  depends_on = [aws_eip.nat]
}
# Attach with NAT Gateway if needed
resource "aws_route" "private_nat_gateway" {
  count = var.enable_gateway ? (var.single_nat_gateway ? 1 : length(var.vpc_cidr_private_subnet)) : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[count.index].id
}
resource "aws_route_table_association" "private" {
  count          = length(var.vpc_cidr_private_subnet)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}


output "vpc_id" {
  description = "ID of the VPC created for EKS cluster"
  value       = aws_vpc.eks_vpc.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC created for EKS cluster"
  value       = aws_vpc.eks_vpc.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets created for EKS cluster"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets created for EKS cluster"
  value       = aws_subnet.private[*].id
}

output "vpc_arn" {
  description = "ARN of the VPC created for EKS cluster"
  value       = aws_vpc.eks_vpc.arn
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway attached to the VPC"
  value       = aws_internet_gateway.igw.id
}


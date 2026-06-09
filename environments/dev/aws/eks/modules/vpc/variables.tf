variable "vpc_cidr_public_subnet" {
  description = "CIDR block for the public subnet in the VPC"
  type        = list(string)
  
}

variable "vpc_cidr_private_subnet" {
  description = "CIDR block for the private subnet in the VPC"
  type        = list(string)

}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "common_tags" {
  type = map(string)
  description = "A map of common tags to apply to all resources"
  
}

variable "enable_gateway" {
  description = "Whether to create an Internet Gateway for the VPC"
  type        = bool

}

variable "single_nat_gateway" {
  description = "Whether to create a single NAT Gateway for the private subnets"
  type        = bool
  
}


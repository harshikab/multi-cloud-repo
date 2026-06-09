variable "cluster-name" {
    description = "Name of the EKS cluster"
    type        = string
    default     = "eks-cluster-dev"
  
}

variable "region" {
  type = string
  description = "The AWS region to deploy resources in"  
  default = "us-east-1"
}

variable "common_tags" {
  type = map(string)
  description = "A map of common tags to apply to all resources"
  default = {
    Owner       = "DevOps-Team"
    Department  = "Engineering"
    CostCenter  = "Engineering001"
    Project     = "TerraformLearning"
  }
  
}

variable "cidr_block" {
    type = list(string)
    description = "The CIDR blocks for the VPC"
    default = [ "10.0.0.0/16", "172.16.0.0/16" ,"192.168.0.0/16" ]
}

variable "EKS_ACCOUNT_ID" {
  type = string
  description = "The AWS account ID for the EKS instances to allow cross-account access"
  
}

variable "enable_gateway" {
  description = "Whether to create an Internet Gateway for the VPC"
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Whether to create a single NAT Gateway for the private subnets"
  type        = bool
  default     = false
}

variable "vpc_cidr_public_subnet" {
  description = "CIDR block for the public subnet in the VPC"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24","10.0.3.0/24"]
}

variable "vpc_cidr_private_subnet" {
  description = "CIDR block for the private subnet in the VPC"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24","10.0.6.0/24"]
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
variable "environment" {
  description = "The name of the environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
  
}

variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "The availability zones to deploy resources in"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "tags" {
    description = "A map of tags to apply to resources"
    type        = map(string)
    default     = {}
    
  
}
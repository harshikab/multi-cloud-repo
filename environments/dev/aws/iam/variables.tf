variable "region" {
  type = string
  description = "The AWS region to deploy resources in"  
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


variable "environment" {
   type = string
   description = "The type of environment"
}





variable "destination_user" {
  type = string
  description = "Assume role user"
}




variable "EC2_ACCOUNT_ID" {
  type = string
  description = "The AWS account ID for the EC2 instances to allow cross-account access"
  
}

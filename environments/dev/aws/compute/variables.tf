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

variable "instance_type" {
    type = list(string)
    description = "Type of instance"
    default = [ "t2.micro", "t3.micro" , "t2.small", "t3.small" ]
}

variable "instance_count" {
    type = number
    description = "Number of instances to create"
   
}

variable "availability_zones" {
    type = set(string)
    description = "The availability zones to deploy resources in"
}

variable "environment" {
   type = string
   description = "The type of environment"
}

variable "cidr_block" {
    type = list(string)
    description = "The CIDR blocks for the VPC"
    default = [ "10.0.0.0/16", "172.16.0.0/16" ,"192.168.0.0/16" ]
}

variable "root_storage_size" {
      type = string
      description = "Root volume size"
      default = "10"
}


variable "github_repo_url" {
      type = string
      description = "GitHub repository URL for the web application"
  
}

variable "github_runner_token" {
      type = string
      description = "GitHub runner token for authentication"
  
}

variable "bucket_name" {
     type = list(string)
     description = "The name of the S3 bucket to create"
     default = [ "harshika-terraform-1","harshika-terraform-2" ]

}

variable "dependent_bucket_name" {
     type = set(string)
     description = "The name of the S3 bucket to create"
     default = [ "harshika-terraform-dependent-1","harshika-terraform-dependent-2" ]

}


variable "EC2_ACCOUNT_ID" {
  type = string
  description = "The AWS account ID for the EC2 instances to allow cross-account access"
  
}
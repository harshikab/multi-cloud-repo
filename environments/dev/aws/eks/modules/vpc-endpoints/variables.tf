variable "region" {
    description = "The AWS region to deploy resources in"
    type        = string
}

variable "vpc_id" {
    description = "The ID of the VPC to create endpoints in"
    type        = string
}

variable "subnet_ids" {
    description = "List of subnet IDs to associate with the VPC endpoints"
    type        = list(string)
}

variable "tags" {
    description = "A map of tags to apply to resources"
    type        = map(string)
   
}
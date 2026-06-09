terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket = "harshika-eks-cluster-state"
    key    = "eks-cluster/terraform.tfstate"
    region = "us-east-1"
    profile= ""
    encrypt = true
    use_lockfile = true
  }
}


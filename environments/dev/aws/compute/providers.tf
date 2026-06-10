# Configure the AWS Provider
provider "aws" {
  region = var.region

  default_tags {
    tags = var.common_tags
  }

  assume_role {
    role_arn     = "arn:aws:iam::${var.AWS_ACCOUNT_ID}:role/github-actions-terraform-eks"
    session_name = "terraform-session"
  }
}

provider "aws" {
  alias  = "destination"
  region = var.region

  default_tags {
    tags = var.common_tags
  }


}



# Configure the AWS Provider
provider "aws" {
  region = var.region

  default_tags {
    tags = var.common_tags
  }
}

# Provider for source account
provider "aws" {
  alias = "source"
  region = var.region

  default_tags {
    tags = var.common_tags
  }
}

# Provider for destination account
provider "aws" {
  alias = "destination"
  region = var.region

  default_tags {
    tags = var.common_tags
  }
}

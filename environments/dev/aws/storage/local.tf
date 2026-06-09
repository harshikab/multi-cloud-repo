locals {
  common_tags = merge(var.tags,{
    Environment = "dev"
    Project     = "multi-cloud-repo"
  })

  bucket_name = "${var.environment}-terraform-bucket-harshika"
}
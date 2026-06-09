# Create an S3 bucket
resource "aws_s3_bucket" "terraform_bucket" {
  bucket = local.bucket_name

  tags = local.common_tags
      
  
}

resource "aws_s3_bucket_public_access_block" "terraform_bucket" {
  bucket = aws_s3_bucket.terraform_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  
}
resource "aws_s3_bucket_versioning" "terraform_bucket" {
  bucket = aws_s3_bucket.terraform_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
  
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_bucket" {
  bucket = aws_s3_bucket.terraform_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
  
}
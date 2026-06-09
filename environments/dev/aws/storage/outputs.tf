output "s3_bucket_domain_name" {
    description = "The domain name of the S3 bucket"
    value       = aws_s3_bucket.terraform_bucket.bucket_domain_name
  
}

output "common_tags" {
    description = "The common tags applied to resources"
    value       = local.common_tags
  
}


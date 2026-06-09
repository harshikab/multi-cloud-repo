resource "aws_key_pair" "key_pair" {
  key_name   = "terraform-key-pair"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "web_server" {
  ami           = "ami-056244ee7f6e2feb8"
  instance_type = var.instance_type[0]
  count         = var.instance_count
  root_block_device {
    volume_size = var.root_storage_size
    volume_type = "gp3"
    tags        = {}
  }
  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = 20
    volume_type = "gp3"
    tags = {
      Name = "terraform-web-server-${count.index + 1}-ebs"
    }

  }
  key_name = aws_key_pair.key_pair.key_name
  tags = merge(var.common_tags, {
    Name = "terraform-web-server-${count.index + 1}"
  })

  user_data = templatefile("${path.module}/../scripts/git-runner.sh", {
    repo_url     = var.github_repo_url
    runner_token = var.github_runner_token
  })
  vpc_security_group_ids = [aws_security_group.ec2_gitrunner.id]


  depends_on = [aws_security_group.ec2_gitrunner]
}

# Crreate KMS key for S3 and EBS encryption to demonstrate best practices for encryption and key management

resource "aws_kms_key" "s3_encryption_key" {
  description             = "Temporary S3 Encryption Key"
  deletion_window_in_days = 7 # Drops it to the AWS minimum
  tags = merge(
    var.common_tags,
     {
       Name = "terraform-s3-encryption-key"
     }

  )  
}

resource "aws_kms_alias" "s3_encryption_alias" {

   name          = "alias/s3_encryption_alias"
   target_key_id = aws_kms_key.s3_encryption_key.key_id
}

# Create s3 buckets with different configurations to demonstrate dependencies and best practices
resource "aws_s3_bucket" "s3-bucket-primary" {
  provider = aws.destination
  count    = length(var.bucket_name)
  bucket   = var.bucket_name[count.index]
  tags     = var.common_tags
  

  depends_on = [aws_instance.web_server]
}

# Block public access for the primary buckets and enable versioning
resource "aws_s3_bucket_public_access_block" "primary_fast_follow" {
  provider = aws.destination
  count    = length(var.bucket_name)
  bucket   = aws_s3_bucket.s3-bucket-primary[count.index].id

  # FIX: AWS-0086, AWS-0087, AWS-0091, AWS-0093, AWS-0094
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "primary_versioning" {
  provider = aws.destination
  count    = length(var.bucket_name)
  bucket   = aws_s3_bucket.s3-bucket-primary[count.index].id
  
  versioning_configuration {
    status = "Enabled" # FIX: AWS-0090
  }
}
# Logging configuration for the dependent buckets to demonstrate cross-account access and logging best practices
resource "aws_s3_bucket_logging" "primary_logging" {
  provider = aws.destination
  count    = length(var.bucket_name)
  bucket   = aws_s3_bucket.s3-bucket-primary[count.index].id

  target_bucket = var.log_sharing_bucket_id # FIX: AWS-0089
  target_prefix = "log/primary-${count.index}/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "primary_encryption" {
  provider = aws.destination
  count    = length(var.bucket_name)
  bucket   = aws_s3_bucket.s3-bucket-primary[count.index].id

  rule {
    bucket_key_enabled = true #  CRITICAL: Drastically reduces S3-to-KMS API request costs
    
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.s3_encryption_alias.arn # FIX: AWS-0132
      sse_algorithm     = "aws:kms"
    }
  }
}


resource "aws_s3_bucket" "s3-bucket-dependent" {
  provider = aws.destination
  for_each = var.dependent_bucket_name
  bucket   = each.key
  tags     = var.common_tags

  depends_on = [aws_s3_bucket.s3-bucket-primary]
}

# Block public access for the dependent buckets and enable versioning
resource "aws_s3_bucket_public_access_block" "dependent_fast_follow" {
  provider = aws.destination
  count    = length(var.bucket_name)
  bucket   = aws_s3_bucket.s3-bucket-dependent[count.index].id

  # FIX: AWS-0086, AWS-0087, AWS-0091, AWS-0093, AWS-0094
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "dependent_versioning" {
  provider = aws.destination
  count    = length(var.bucket_name)
  bucket   = aws_s3_bucket.s3-bucket-dependent[count.index].id
  
  versioning_configuration {
    status = "Enabled" # FIX: AWS-0090
  }
}
# Logging configuration for the dependent buckets to demonstrate cross-account access and logging best practices
resource "aws_s3_bucket_logging" "dependent_logging" {
  provider = aws.destination
  count    = length(var.bucket_name)
  bucket   = aws_s3_bucket.s3-bucket-dependent[count.index].id

  target_bucket = var.log_sharing_bucket_id # FIX: AWS-0089
  target_prefix = "log/dependent-${count.index}/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dependent_encryption" {
  provider = aws.destination
  count    = length(var.bucket_name)
  bucket   = aws_s3_bucket.s3-bucket-dependent[count.index].id

  rule {
    bucket_key_enabled = true #  CRITICAL: Drastically reduces S3-to-KMS API request costs
    
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.s3_encryption_alias.arn # FIX: AWS-0132
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_key_pair" "key_pair" {
  key_name   = "terraform-key-pair"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "web_server" {
  ami = "ami-056244ee7f6e2feb8"
  instance_type = var.instance_type[0]
  count = var.instance_count
  root_block_device {
    volume_size = var.root_storage_size
    volume_type = "gp3"
    tags = {}
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

  
  depends_on = [ aws_security_group.ec2_gitrunner ]
}

resource "aws_s3_bucket" "s3-bucket-primary" {
  provider   = aws.destination
  count = length(var.bucket_name)
  bucket = var.bucket_name[count.index]
  tags   = var.common_tags

  depends_on = [ aws_instance.web_server ]
}

resource "aws_s3_bucket" "s3-bucket-dependent" {
  provider   = aws.destination
  for_each = var.dependent_bucket_name
  bucket = each.key
  tags   = var.common_tags

  depends_on = [ aws_s3_bucket.s3-bucket-primary ]
}

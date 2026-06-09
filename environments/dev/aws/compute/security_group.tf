resource "aws_security_group" "ec2_gitrunner" {
  name        = "ec2_security_group_terraform_gitrunner"
  description = "Security group for EC2 instances"
  

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cidr_block
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.cidr_block
  }
  tags = var.common_tags
}
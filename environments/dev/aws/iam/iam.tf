data "aws_caller_identity" "source" {
  provider = aws.source
}

# Assume role policy document for cross-account access
data "aws_iam_policy_document" "assume_role" {
  provider = aws.destination
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.source.account_id}:user/${var.destination_user}"]
    }
  }
}

# Create an IAM role in the destination account that allows the source account to assume it
resource "aws_iam_role" "ec2_creator_role" {
    provider = aws.destination
    name = "EC2CreatorRole"
    assume_role_policy = data.aws_iam_policy_document.assume_role.json
  
}

# Attach the AmazonEC2FullAccess policy to the role in the destination account
resource "aws_iam_role_policy_attachment" "ec2_full_access_attachment" {
    provider = aws.destination
    role       = aws_iam_role.ec2_creator_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# 2. VPC/Networking Permissions
resource "aws_iam_role_policy_attachment" "vpc_full_access_attachment" {
    provider   = aws.destination
    role       = aws_iam_role.ec2_creator_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
    provider   = aws.destination
    role       = aws_iam_role.ec2_creator_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "enable_ssm_for_ec2_attachment" {
    provider   = aws.destination
    role       = aws_iam_role.ec2_creator_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedEC2InstanceDefaultPolicy"
}
 
# Allow the destination user to assume the role
resource "aws_iam_user_policy" "destination_user_assume_policy" {
    provider = aws.destination
    name = "EC2UserAssumePolicy"
    user = var.destination_user
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = "sts:AssumeRole"
                Resource = aws_iam_role.ec2_creator_role.arn
            }
        ]
    })
}
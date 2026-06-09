locals {
    service=[
        "eks",             # EKS Control plane communication
        "ec2",             # For managed node groups / EC2 API
        "ecr.api",         # ECR API for authentication
        "ecr.dkr",         # ECR Docker registry for image pulling
        "logs",            # CloudWatch Logs (FluentBit/Container Insights)
        "sts"              # AWS Security Token Service (for IAM Roles for Service Accounts - IRSA)
  ]
    
}
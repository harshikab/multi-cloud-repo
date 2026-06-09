# Create an IAM role in the destination account that allows the source account to assume it
resource "aws_iam_role" "eks-cluster-role" {
    name = "${var.cluster-name}-eks-cluster-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = {
                    Service = "eks.amazonaws.com"
                }
                Action = "sts:AssumeRole"
            }
        ]
    })
  
}

# Attach the AmazonEKSClusterPolicy to the role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" { 
    role       = aws_iam_role.eks-cluster-role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Attach the AmazonEKSVPCResourceController to the role
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller_attachment" { 
    role       = aws_iam_role.eks-cluster-role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# Node group role
resource "aws_iam_role" "eks_nodegroup_role" {
    name = "${var.cluster-name}-eks-nodegroup-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
                Action = "sts:AssumeRole"
            }
        ]
    })
    
  
}

# Attach the AmazonEKSWorkerNodePolicy to the node group role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy_attachment" { 
    role       = aws_iam_role.eks_nodegroup_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Attach the AmazonEC2ContainerRegistryReadOnly policy to the node group role
resource "aws_iam_role_policy_attachment" "eks_ecr_readonly_attachment" { 
    role       = aws_iam_role.eks_nodegroup_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Attach the AmazonSSMManagedInstanceCore policy to the node group role
resource "aws_iam_role_policy_attachment" "eks_ssm_managed_attachment" { 
    role       = aws_iam_role.eks_nodegroup_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach the AmazonEks_CNI_Policy to the node group role
resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" { 
    role       = aws_iam_role.eks_nodegroup_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Attach the CloudwatchAgentServerPolicy to the node group role for monitoring
resource "aws_iam_role_policy_attachment" "eks_cloudwatch_agent_attachment" { 
    role       = aws_iam_role.eks_nodegroup_role.name
    policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

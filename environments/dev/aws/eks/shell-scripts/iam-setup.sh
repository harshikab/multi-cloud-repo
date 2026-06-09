#!/usr/bin/env bash
# =============================================================================
# 01-iam/setup.sh — IAM Roles + KMS Key for EKS Secrets Encryption
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../env.sh"

echo "======================================================"
echo " Step 1: Creating IAM Roles & KMS Key"
echo "======================================================"

# ------------------------------------------------------------------------------
# 1A. EKS Cluster IAM Role
# ------------------------------------------------------------------------------
echo "[1/5] Creating EKS Cluster IAM Role..."

cat > /tmp/eks-cluster-trust.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "eks.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
EOF

aws iam create-role \
  --role-name "${CLUSTER_ROLE_NAME}" \
  --assume-role-policy-document file:///tmp/eks-cluster-trust.json \
  --description "EKS Cluster role for ${CLUSTER_NAME}" \
  --tags Key=Cluster,Value=${CLUSTER_NAME} Key=Environment,Value=${TAG_ENV} \
  --output text --query 'Role.RoleName' 2>/dev/null || echo "  (role already exists)"

aws iam attach-role-policy --role-name "${CLUSTER_ROLE_NAME}" \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

aws iam attach-role-policy --role-name "${CLUSTER_ROLE_NAME}" \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSVPCResourceController

CLUSTER_ROLE_ARN=$(aws iam get-role --role-name "${CLUSTER_ROLE_NAME}" \
  --query 'Role.Arn' --output text)
echo "  Cluster Role ARN: ${CLUSTER_ROLE_ARN}"

# ------------------------------------------------------------------------------
# 1B. EKS Node Group IAM Role
# ------------------------------------------------------------------------------
echo "[2/5] Creating EKS Node Group IAM Role..."

cat > /tmp/eks-node-trust.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "ec2.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
EOF

aws iam create-role \
  --role-name "${NODE_ROLE_NAME}" \
  --assume-role-policy-document file:///tmp/eks-node-trust.json \
  --description "EKS Node Group role for ${CLUSTER_NAME}" \
  --tags Key=Cluster,Value=${CLUSTER_NAME} Key=Environment,Value=${TAG_ENV} \
  --output text --query 'Role.RoleName' 2>/dev/null || echo "  (role already exists)"

for policy in \
  arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy \
  arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy \
  arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly \
  arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
  arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore; do
  aws iam attach-role-policy --role-name "${NODE_ROLE_NAME}" --policy-arn "$policy"
done

NODE_ROLE_ARN=$(aws iam get-role --role-name "${NODE_ROLE_NAME}" \
  --query 'Role.Arn' --output text)
echo "  Node Role ARN: ${NODE_ROLE_ARN}"

# ------------------------------------------------------------------------------
# 1C. Custom Node Policy — Allow nodes to write to CloudWatch & pull ECR
# ------------------------------------------------------------------------------
echo "[3/5] Creating custom node policy..."

cat > /tmp/node-custom-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": "arn:aws:logs:${AWS_REGION}:${ACCOUNT_ID}:log-group:/aws/eks/${CLUSTER_NAME}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": "*"
    }
  ]
}
EOF

CUSTOM_POLICY_ARN=$(aws iam create-policy \
  --policy-name "${CLUSTER_NAME}-node-custom-policy" \
  --policy-document file:///tmp/node-custom-policy.json \
  --query 'Policy.Arn' --output text 2>/dev/null || \
  aws iam list-policies --query "Policies[?PolicyName=='${CLUSTER_NAME}-node-custom-policy'].Arn" \
  --output text)

aws iam attach-role-policy --role-name "${NODE_ROLE_NAME}" \
  --policy-arn "${CUSTOM_POLICY_ARN}"
echo "  Custom policy attached: ${CUSTOM_POLICY_ARN}"

# ------------------------------------------------------------------------------
# 1D. IRSA — Enable IAM Roles for Service Accounts
#     (OIDC provider created after cluster; placeholder here)
# ------------------------------------------------------------------------------
echo "[4/5] IRSA note: OIDC provider will be registered after cluster creation (step 05)."

# ------------------------------------------------------------------------------
# 1E. KMS Key for EKS Secrets Envelope Encryption
# ------------------------------------------------------------------------------
echo "[5/5] Creating KMS key for secrets encryption..."

KMS_KEY_ID=$(aws kms create-key \
  --description "EKS secrets encryption key for ${CLUSTER_NAME}" \
  --key-usage ENCRYPT_DECRYPT \
  --origin AWS_KMS \
  --tags TagKey=Cluster,TagValue=${CLUSTER_NAME} TagKey=Environment,TagValue=${TAG_ENV} \
  --query 'KeyMetadata.KeyId' --output text 2>/dev/null || true)

if [ -z "${KMS_KEY_ID}" ]; then
  # Key may already exist; look it up by alias
  KMS_KEY_ID=$(aws kms describe-key --key-id "${KMS_ALIAS}" \
    --query 'KeyMetadata.KeyId' --output text 2>/dev/null || true)
fi

if [ -n "${KMS_KEY_ID}" ]; then
  aws kms create-alias \
    --alias-name "${KMS_ALIAS}" \
    --target-key-id "${KMS_KEY_ID}" 2>/dev/null || echo "  (alias already exists)"

  # Enable automatic key rotation
  aws kms enable-key-rotation --key-id "${KMS_KEY_ID}"
  KMS_KEY_ARN=$(aws kms describe-key --key-id "${KMS_KEY_ID}" \
    --query 'KeyMetadata.Arn' --output text)
  echo "  KMS Key ARN: ${KMS_KEY_ARN}"
else
  echo "  WARNING: Could not create KMS key. Check permissions."
fi

# ------------------------------------------------------------------------------
# Save outputs
# ------------------------------------------------------------------------------
cat > "$(dirname "$0")/outputs.env" << EOF
CLUSTER_ROLE_ARN=${CLUSTER_ROLE_ARN}
NODE_ROLE_ARN=${NODE_ROLE_ARN}
KMS_KEY_ARN=${KMS_KEY_ARN:-""}
EOF

echo ""
echo "✅  Step 1 complete. Outputs saved to 01-iam/outputs.env"
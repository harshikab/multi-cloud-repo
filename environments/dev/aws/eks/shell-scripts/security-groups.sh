#!/usr/bin/env bash
# =============================================================================
# 03-security-groups/setup.sh — Cluster, Node, and VPC Endpoint Security Groups
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../env.sh"
source "$(dirname "$0")/../02-vpc/outputs.env"

echo "======================================================"
echo " Step 3: Creating Security Groups"
echo "======================================================"

tag() {
  aws ec2 create-tags --resources "$1" \
    --tags Key=Name,Value="$2" Key=Environment,Value=${TAG_ENV} Key=Cluster,Value=${CLUSTER_NAME}
}

# ------------------------------------------------------------------------------
# 3A. EKS Cluster Security Group (control plane ENIs)
# ------------------------------------------------------------------------------
echo "[1/4] Creating Cluster Security Group..."
CLUSTER_SG=$(aws ec2 create-security-group \
  --group-name "${CLUSTER_NAME}-cluster-sg" \
  --description "EKS Cluster control plane SG" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)
tag $CLUSTER_SG "${CLUSTER_NAME}-cluster-sg"
echo "  Cluster SG: ${CLUSTER_SG}"

# ------------------------------------------------------------------------------
# 3B. EKS Node Security Group
# ------------------------------------------------------------------------------
echo "[2/4] Creating Node Security Group..."
NODE_SG=$(aws ec2 create-security-group \
  --group-name "${CLUSTER_NAME}-node-sg" \
  --description "EKS Worker Node SG" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)
tag $NODE_SG "${CLUSTER_NAME}-node-sg"

## Inbound: nodes talk to each other (all traffic within node SG)
aws ec2 authorize-security-group-ingress --group-id $NODE_SG \
  --source-group $NODE_SG --protocol -1 --port -1

## Inbound: control plane → nodes (kubelet, metrics, webhooks)
aws ec2 authorize-security-group-ingress --group-id $NODE_SG \
  --source-group $CLUSTER_SG --protocol tcp --port 1025-65535

## Inbound: control plane → nodes HTTPS (admission webhooks)
aws ec2 authorize-security-group-ingress --group-id $NODE_SG \
  --source-group $CLUSTER_SG --protocol tcp --port 443

## Outbound: all (nodes need to reach NAT GW → internet for ECR/updates)
aws ec2 authorize-security-group-egress --group-id $NODE_SG \
  --protocol -1 --cidr 0.0.0.0/0

echo "  Node SG: ${NODE_SG}"

# ------------------------------------------------------------------------------
# 3C. Cluster SG ingress/egress (after node SG exists)
# ------------------------------------------------------------------------------
echo "[3/4] Configuring Cluster SG rules..."

## Inbound: nodes → control plane HTTPS
aws ec2 authorize-security-group-ingress --group-id $CLUSTER_SG \
  --source-group $NODE_SG --protocol tcp --port 443

## Inbound: bastion → control plane (for kubectl from bastion)
aws ec2 authorize-security-group-ingress --group-id $CLUSTER_SG \
  --source-group $BASTION_SG --protocol tcp --port 443

## Outbound: control plane → nodes
aws ec2 authorize-security-group-egress --group-id $CLUSTER_SG \
  --source-group $NODE_SG --protocol tcp --port 1025-65535

aws ec2 authorize-security-group-egress --group-id $CLUSTER_SG \
  --source-group $NODE_SG --protocol tcp --port 443

# ------------------------------------------------------------------------------
# 3D. VPC Endpoint Security Group
# ------------------------------------------------------------------------------
echo "[4/4] Creating VPC Endpoint Security Group..."
ENDPOINT_SG=$(aws ec2 create-security-group \
  --group-name "${CLUSTER_NAME}-endpoint-sg" \
  --description "VPC Interface Endpoints SG" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)
tag $ENDPOINT_SG "${CLUSTER_NAME}-endpoint-sg"

## Inbound: nodes → endpoints HTTPS
aws ec2 authorize-security-group-ingress --group-id $ENDPOINT_SG \
  --source-group $NODE_SG --protocol tcp --port 443

## Inbound: cluster → endpoints HTTPS
aws ec2 authorize-security-group-ingress --group-id $ENDPOINT_SG \
  --source-group $CLUSTER_SG --protocol tcp --port 443

## Inbound: bastion → endpoints HTTPS
aws ec2 authorize-security-group-ingress --group-id $ENDPOINT_SG \
  --source-group $BASTION_SG --protocol tcp --port 443

echo "  Endpoint SG: ${ENDPOINT_SG}"

# Save outputs
cat > "$(dirname "$0")/outputs.env" << EOF
CLUSTER_SG=${CLUSTER_SG}
NODE_SG=${NODE_SG}
ENDPOINT_SG=${ENDPOINT_SG}
EOF

echo ""
echo "✅  Step 3 complete. Outputs saved to 03-security-groups/outputs.env"
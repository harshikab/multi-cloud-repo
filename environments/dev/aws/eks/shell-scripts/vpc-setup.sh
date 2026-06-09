#!/usr/bin/env bash
# =============================================================================
# 02-vpc/setup.sh — Production VPC: 3 public + 3 private subnets, 3 NAT GWs
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../env.sh"

echo "======================================================"
echo " Step 2: Creating VPC & Networking"
echo "======================================================"

tag() { aws ec2 create-tags --resources "$1" --tags Key=Name,Value="$2" \
  Key=Environment,Value=${TAG_ENV} Key=Cluster,Value=${CLUSTER_NAME}; }

# ------------------------------------------------------------------------------
# 2A. VPC
# ------------------------------------------------------------------------------
echo "[1/9] Creating VPC..."
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block "${VPC_CIDR}" \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${CLUSTER_NAME}-vpc},{Key=Environment,Value=${TAG_ENV}},{Key=Cluster,Value=${CLUSTER_NAME}}]" \
  --query 'Vpc.VpcId' --output text)

aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support
echo "  VPC: ${VPC_ID}"

# ------------------------------------------------ ------------------------------
# 2B. Internet Gateway
# ------------------------------------------------------------------------------
echo "[2/9] Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
  --query 'InternetGateway.InternetGatewayId' --output text)
tag $IGW_ID "${CLUSTER_NAME}-igw"
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID
echo "  IGW: ${IGW_ID}"

# ------------------------------------------------------------------------------
# 2C. Public Subnets
# ------------------------------------------------------------------------------
echo "[3/9] Creating public subnets (x3 AZs)..."

create_pub_subnet() {
  local cidr=$1 az=$2 name=$3
  local id=$(aws ec2 create-subnet --vpc-id $VPC_ID \
    --cidr-block "$cidr" --availability-zone "$az" \
    --query 'Subnet.SubnetId' --output text)
  aws ec2 modify-subnet-attribute --subnet-id $id --map-public-ip-on-launch
  tag $id "$name"
  # EKS tags for external load balancers
  aws ec2 create-tags --resources $id --tags \
    "Key=kubernetes.io/cluster/${CLUSTER_NAME},Value=shared" \
    "Key=kubernetes.io/role/elb,Value=1"
  echo "$id"
}

PUB_SUBNET_A=$(create_pub_subnet $PUB_SUBNET_AZ_A $AZ_A "${CLUSTER_NAME}-pub-a")
PUB_SUBNET_B=$(create_pub_subnet $PUB_SUBNET_AZ_B $AZ_B "${CLUSTER_NAME}-pub-b")
PUB_SUBNET_C=$(create_pub_subnet $PUB_SUBNET_AZ_C $AZ_C "${CLUSTER_NAME}-pub-c")
echo "  Public subnets: ${PUB_SUBNET_A}, ${PUB_SUBNET_B}, ${PUB_SUBNET_C}"

# ------------------------------------------------------------------------------
# 2D. Private Subnets
# ------------------------------------------------------------------------------
echo "[4/9] Creating private subnets (x3 AZs)..."

create_priv_subnet() {
  local cidr=$1 az=$2 name=$3
  local id=$(aws ec2 create-subnet --vpc-id $VPC_ID \
    --cidr-block "$cidr" --availability-zone "$az" \
    --query 'Subnet.SubnetId' --output text)
  tag $id "$name"
  # EKS tags for internal load balancers
  aws ec2 create-tags --resources $id --tags \
    "Key=kubernetes.io/cluster/${CLUSTER_NAME},Value=shared" \
    "Key=kubernetes.io/role/internal-elb,Value=1"
  echo "$id"
}

PRIV_SUBNET_A=$(create_priv_subnet $PRIV_SUBNET_AZ_A $AZ_A "${CLUSTER_NAME}-priv-a")
PRIV_SUBNET_B=$(create_priv_subnet $PRIV_SUBNET_AZ_B $AZ_B "${CLUSTER_NAME}-priv-b")
PRIV_SUBNET_C=$(create_priv_subnet $PRIV_SUBNET_AZ_C $AZ_C "${CLUSTER_NAME}-priv-c")
echo "  Private subnets: ${PRIV_SUBNET_A}, ${PRIV_SUBNET_B}, ${PRIV_SUBNET_C}"

# ------------------------------------------------------------------------------
# 2E. Elastic IPs + NAT Gateways (one per AZ for HA)
# ------------------------------------------------------------------------------
echo "[5/9] Allocating Elastic IPs & creating NAT Gateways (3x)..."

create_nat() {
  local subnet=$1 az_label=$2
  local eip=$(aws ec2 allocate-address --domain vpc \
    --query 'AllocationId' --output text)
  tag $eip "${CLUSTER_NAME}-eip-${az_label}"
  local nat=$(aws ec2 create-nat-gateway \
    --subnet-id "$subnet" --allocation-id "$eip" \
    --query 'NatGateway.NatGatewayId' --output text)
  tag $nat "${CLUSTER_NAME}-nat-${az_label}"
  echo "$nat"
}

NAT_A=$(create_nat $PUB_SUBNET_A "a")
NAT_B=$(create_nat $PUB_SUBNET_B "b")
NAT_C=$(create_nat $PUB_SUBNET_C "c")

echo "  Waiting for NAT Gateways to become available..."
aws ec2 wait nat-gateway-available --filter Name=nat-gateway-id,Values=$NAT_A
aws ec2 wait nat-gateway-available --filter Name=nat-gateway-id,Values=$NAT_B
aws ec2 wait nat-gateway-available --filter Name=nat-gateway-id,Values=$NAT_C
echo "  NAT GWs: ${NAT_A}, ${NAT_B}, ${NAT_C}"

# ------------------------------------------------------------------------------
# 2F. Public Route Table (routes to IGW)
# ------------------------------------------------------------------------------
echo "[6/9] Creating public route table..."
PUB_RT=$(aws ec2 create-route-table --vpc-id $VPC_ID \
  --query 'RouteTable.RouteTableId' --output text)
tag $PUB_RT "${CLUSTER_NAME}-rt-public"
aws ec2 create-route --route-table-id $PUB_RT \
  --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

for subnet in $PUB_SUBNET_A $PUB_SUBNET_B $PUB_SUBNET_C; do
  aws ec2 associate-route-table --subnet-id $subnet --route-table-id $PUB_RT
done

# ------------------------------------------------------------------------------
# 2G. Private Route Tables (one per AZ, routes to respective NAT GW)
# ------------------------------------------------------------------------------
echo "[7/9] Creating private route tables (per-AZ)..."

create_priv_rt() {
  local subnet=$1 nat=$2 az_label=$3
  local rt=$(aws ec2 create-route-table --vpc-id $VPC_ID \
    --query 'RouteTable.RouteTableId' --output text)
  tag $rt "${CLUSTER_NAME}-rt-priv-${az_label}"
  aws ec2 create-route --route-table-id $rt \
    --destination-cidr-block 0.0.0.0/0 --nat-gateway-id "$nat"
  aws ec2 associate-route-table --subnet-id "$subnet" --route-table-id $rt
  echo "$rt"
}

PRIV_RT_A=$(create_priv_rt $PRIV_SUBNET_A $NAT_A "a")
PRIV_RT_B=$(create_priv_rt $PRIV_SUBNET_B $NAT_B "b")
PRIV_RT_C=$(create_priv_rt $PRIV_SUBNET_C $NAT_C "c")

# ------------------------------------------------------------------------------
# 2H. Bastion Host (SSM-only, no public SSH port)
# ------------------------------------------------------------------------------
echo "[8/9] Launching Bastion host (SSM access only)..."

# Get latest Amazon Linux 2023 AMI
BASTION_AMI=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-2023*-x86_64" \
            "Name=state,Values=available" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text)

# Bastion IAM role for SSM
cat > /tmp/bastion-trust.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "ec2.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
EOF

aws iam create-role --role-name "${CLUSTER_NAME}-bastion-role" \
  --assume-role-policy-document file:///tmp/bastion-trust.json \
  --output text --query 'Role.RoleName' 2>/dev/null || true

aws iam attach-role-policy --role-name "${CLUSTER_NAME}-bastion-role" \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
aws iam attach-role-policy --role-name "${CLUSTER_NAME}-bastion-role" \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

BASTION_PROFILE=$(aws iam create-instance-profile \
  --instance-profile-name "${CLUSTER_NAME}-bastion-profile" \
  --query 'InstanceProfile.InstanceProfileName' --output text 2>/dev/null || \
  echo "${CLUSTER_NAME}-bastion-profile")

aws iam add-role-to-instance-profile \
  --instance-profile-name "${CLUSTER_NAME}-bastion-profile" \
  --role-name "${CLUSTER_NAME}-bastion-role" 2>/dev/null || true
sleep 10  # propagation delay

BASTION_SG=$(aws ec2 create-security-group \
  --group-name "${CLUSTER_NAME}-bastion-sg" \
  --description "Bastion — SSM only, no inbound SSH" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)
tag $BASTION_SG "${CLUSTER_NAME}-bastion-sg"
# No inbound rules — SSM tunnels over HTTPS via VPC Endpoint

BASTION_ID=$(aws ec2 run-instances \
  --image-id $BASTION_AMI \
  --instance-type t3.micro \
  --subnet-id $PUB_SUBNET_A \
  --security-group-ids $BASTION_SG \
  --iam-instance-profile Name="${CLUSTER_NAME}-bastion-profile" \
  --metadata-options HttpTokens=required,HttpEndpoint=enabled \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${CLUSTER_NAME}-bastion},{Key=Environment,Value=${TAG_ENV}},{Key=Cluster,Value=${CLUSTER_NAME}}]" \
  --query 'Instances[0].InstanceId' --output text)

echo "  Bastion: ${BASTION_ID} (connect via: aws ssm start-session --target ${BASTION_ID})"

# ------------------------------------------------------------------------------
# 2I. Save outputs
# ------------------------------------------------------------------------------
echo "[9/9] Saving VPC outputs..."
cat > "$(dirname "$0")/outputs.env" << EOF
VPC_ID=${VPC_ID}
IGW_ID=${IGW_ID}
PUB_SUBNET_A=${PUB_SUBNET_A}
PUB_SUBNET_B=${PUB_SUBNET_B}
PUB_SUBNET_C=${PUB_SUBNET_C}
PRIV_SUBNET_A=${PRIV_SUBNET_A}
PRIV_SUBNET_B=${PRIV_SUBNET_B}
PRIV_SUBNET_C=${PRIV_SUBNET_C}
NAT_A=${NAT_A}
NAT_B=${NAT_B}
NAT_C=${NAT_C}
BASTION_ID=${BASTION_ID}
BASTION_SG=${BASTION_SG}
EOF

echo ""
echo "✅  Step 2 complete. Outputs saved to 02-vpc/outputs.env"
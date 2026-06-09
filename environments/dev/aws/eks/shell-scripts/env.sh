#!/usr/bin/env bash
# =============================================================================
# env.sh — Shared environment variables for all scripts
# Edit these before running any script.
# =============================================================================

export AWS_REGION="us-east-1"
export CLUSTER_NAME="prod-private-eks"
export K8S_VERSION="1.29"
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# VPC CIDR Design
export VPC_CIDR="10.0.0.0/16"

# Public subnets (NAT Gateways, ALB)
export PUB_SUBNET_AZ_A="10.0.0.0/20"
export PUB_SUBNET_AZ_B="10.0.16.0/20"
export PUB_SUBNET_AZ_C="10.0.32.0/20"

# Private subnets (Worker Nodes)
export PRIV_SUBNET_AZ_A="10.0.48.0/20"
export PRIV_SUBNET_AZ_B="10.0.64.0/20"
export PRIV_SUBNET_AZ_C="10.0.80.0/20"

# Availability Zones
export AZ_A="${AWS_REGION}a"
export AZ_B="${AWS_REGION}b"
export AZ_C="${AWS_REGION}c"

# Node Group Instance Types
export SYSTEM_INSTANCE_TYPE="m5.large"
export APP_INSTANCE_TYPE="m5.xlarge"
export SPOT_INSTANCE_TYPES="m5.xlarge,m5a.xlarge,m4.xlarge,m5d.xlarge"

# Node Group Sizes
export SYSTEM_MIN=2; export SYSTEM_MAX=4;  export SYSTEM_DESIRED=2
export APP_MIN=2;    export APP_MAX=10;    export APP_DESIRED=2
export SPOT_MIN=0;   export SPOT_MAX=10;   export SPOT_DESIRED=2

# Disk size (GiB)
export NODE_DISK_SIZE=50

# IAM Role Names
export CLUSTER_ROLE_NAME="${CLUSTER_NAME}-cluster-role"
export NODE_ROLE_NAME="${CLUSTER_NAME}-node-role"

# KMS key alias
export KMS_ALIAS="alias/${CLUSTER_NAME}-secrets"

# Tags applied to all resources
export TAG_ENV="production"
export TAG_TEAM="platform"
export COMMON_TAGS="Key=Environment,Value=${TAG_ENV} Key=Team,Value=${TAG_TEAM} Key=Cluster,Value=${CLUSTER_NAME} Key=ManagedBy,Value=manual"
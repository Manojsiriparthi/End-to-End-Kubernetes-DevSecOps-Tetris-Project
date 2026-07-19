# ==============================================================================
# DEV ENVIRONMENT - MAIN CONFIGURATION
# ==============================================================================
# Description: Development environment EKS infrastructure for Tetris gaming platform
# Environment: Development (Cost-optimized, relaxed security, gaming-friendly)
# Author: Platform Engineering Team
# Version: 2.0.0
# ==============================================================================

terraform {
  required_version = ">= 1.5"
  
  backend "s3" {
    # Backend configuration will be provided via backend config file
    # terraform init -backend-config=backend-dev.hcl
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# ==============================================================================
# PROVIDER CONFIGURATIONS
# ==============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# Data sources for dynamic configuration
data "aws_eks_cluster" "cluster" {
  name = module.eks_cluster.cluster_name
  depends_on = [module.eks_cluster]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.cluster_name
  depends_on = [module.eks_cluster]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# ==============================================================================
# LOCAL VALUES AND COMMON TAGS
# ==============================================================================

locals {
  environment = "dev"
  name_prefix = "${var.project_name}-${local.environment}"
  
  common_tags = {
    Project         = var.project_name
    Environment     = local.environment
    Owner           = var.owner
    ManagedBy      = "terraform"
    CreatedDate    = formatdate("YYYY-MM-DD", timestamp())
    CostCenter     = var.cost_center
    BusinessUnit   = var.business_unit
    BackupRequired = "false"  # Dev doesn't need backup
    Compliance     = "low"    # Dev has lower compliance requirements
  }

  # Availability Zones - Dynamic selection for HA
  availability_zones = data.aws_availability_zones.available.names

  # CIDR Calculations for multi-AZ deployment
  public_subnet_cidrs = [
    for i, az in slice(local.availability_zones, 0, 3) : 
    cidrsubnet(var.vpc_cidr, 8, i + 1)
  ]
  
  private_subnet_cidrs = [
    for i, az in slice(local.availability_zones, 0, 3) : 
    cidrsubnet(var.vpc_cidr, 8, i + 10)
  ]
  
  database_subnet_cidrs = [
    for i, az in slice(local.availability_zones, 0, 3) : 
    cidrsubnet(var.vpc_cidr, 8, i + 20)
  ]
}

# ==============================================================================
# DATA SOURCES
# ==============================================================================

data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ==============================================================================
# NETWORKING MODULE
# ==============================================================================

module "networking" {
  source = "../../modules/networking"

  # Basic Configuration
  project_name       = var.project_name
  environment        = local.environment
  vpc_cidr          = var.vpc_cidr
  availability_zones = slice(local.availability_zones, 0, 3)

  # Subnet Configurations
  public_subnet_cidrs   = local.public_subnet_cidrs
  private_subnet_cidrs  = local.private_subnet_cidrs
  database_subnet_cidrs = local.database_subnet_cidrs

  # Dev-specific HA Configuration (Cost-optimized)
  enable_dns_hostnames     = true
  enable_dns_support       = true
  enable_nat_gateway       = true
  single_nat_gateway       = true  # Cost optimization for dev
  enable_vpn_gateway       = false # Not needed in dev
  create_database_subnet_group = true

  # Security Configuration (Relaxed for dev)
  enable_flow_logs              = false  # Cost optimization
  flow_logs_retention_in_days   = 7      # Minimal retention
  enable_network_firewall       = false  # Not needed in dev

  tags = local.common_tags
}

# ==============================================================================
# KMS MODULE FOR ENCRYPTION
# ==============================================================================

module "kms" {
  source = "../../modules/kms"

  project_name = var.project_name
  environment  = local.environment

  # Key Configuration (Minimal for dev)
  create_cluster_kms_key = true
  create_ebs_kms_key    = false  # Use default EBS encryption in dev
  create_s3_kms_key     = false  # Use default S3 encryption in dev

  # Key Policies
  kms_key_administrators = var.kms_key_administrators
  kms_key_users         = var.kms_key_users

  tags = local.common_tags
}

# ==============================================================================
# IAM MODULE
# ==============================================================================

module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = local.environment
  
  # EKS Cluster Configuration
  cluster_name = local.name_prefix
  
  # Node Group IAM
  node_group_configs = var.node_group_configs
  
  # Service Account Roles (Essential ones for dev)
  create_aws_load_balancer_controller_role = true
  create_cluster_autoscaler_role          = true
  create_external_dns_role                = false  # Not needed in dev
  create_ebs_csi_driver_role             = true
  create_efs_csi_driver_role             = false   # Not needed in dev
  create_cloudwatch_agent_role           = false   # Minimal logging in dev
  create_fluent_bit_role                 = false   # Minimal logging in dev
  create_karpenter_role                  = true
  
  tags = local.common_tags
}

# ==============================================================================
# SECURITY GROUPS MODULE
# ==============================================================================

module "security_groups" {
  source = "../../modules/security-groups"

  project_name = var.project_name
  environment  = local.environment
  vpc_id       = module.networking.vpc_id

  # CIDR Blocks
  vpc_cidr_block       = module.networking.vpc_cidr_block
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs

  # Dev-specific Security (More permissive for development)
  bastion_allowed_cidrs = ["0.0.0.0/0"]  # Open for dev convenience
  
  tags = local.common_tags
  depends_on = [module.networking]
}

# ==============================================================================
# EKS CLUSTER MODULE
# ==============================================================================

module "eks_cluster" {
  source = "../../modules/eks-cluster"

  # Basic Configuration
  cluster_name    = local.name_prefix
  cluster_version = var.eks_cluster_version

  # Networking
  vpc_id                    = module.networking.vpc_id
  subnet_ids               = concat(module.networking.private_subnet_ids, module.networking.public_subnet_ids)
  control_plane_subnet_ids = module.networking.private_subnet_ids

  # Security Groups
  additional_security_group_ids = [
    module.security_groups.eks_cluster_additional_sg_id
  ]

  # Access Configuration (Dev-friendly)
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true   # Allow public access for dev
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]  # Open for dev

  # Logging (Minimal for cost)
  cluster_enabled_log_types = ["api", "audit"]  # Essential logs only
  cloudwatch_log_group_retention_in_days = 7

  # OIDC Provider
  enable_irsa = true

  # Encryption (Basic for dev)
  cluster_encryption_config = [{
    provider_key_arn = module.kms.cluster_kms_key_arn
    resources        = ["secrets"]
  }]

  # IAM Roles
  cluster_service_role_arn = module.iam.eks_cluster_role_arn

  # Add-ons Management
  manage_aws_auth_configmap = true
  
  # RBAC Configuration
  aws_auth_roles = var.aws_auth_roles
  aws_auth_users = var.aws_auth_users

  tags = local.common_tags

  depends_on = [
    module.networking,
    module.iam,
    module.security_groups
  ]
}

# ==============================================================================
# NODE GROUPS MODULE
# ==============================================================================

module "node_groups" {
  source = "../../modules/node-groups"

  # Basic Configuration
  cluster_name = module.eks_cluster.cluster_name
  
  # Networking
  subnet_ids = {
    public   = module.networking.public_subnet_ids
    private  = module.networking.private_subnet_ids
    database = module.networking.database_subnet_ids
  }

  # Node Group Configurations
  node_groups = var.node_group_configs

  # IAM
  node_group_role_arn = module.iam.eks_node_group_role_arn

  # Security
  worker_security_group_id = module.eks_cluster.node_security_group_id
  additional_security_group_ids = [
    module.security_groups.eks_nodes_sg_id
  ]

  # Launch Template Configuration
  enable_bootstrap_user_data = true
  
  # KMS (if enabled)
  kms_key_id = module.kms.ebs_kms_key_id

  tags = local.common_tags

  depends_on = [
    module.eks_cluster,
    module.iam,
    module.security_groups
  ]
}
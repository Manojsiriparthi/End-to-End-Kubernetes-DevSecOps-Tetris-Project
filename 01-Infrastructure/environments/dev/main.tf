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

# Data sources for EKS authentication (using new module outputs)
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
    GamingPlatform = "tetris"
    InfrastructureType = "gaming-development"
  }

  # Availability Zones - Dynamic selection for HA
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)  # Use 2 AZs for dev cost optimization

  # CIDR Calculations for multi-AZ deployment (gaming-optimized)
  public_subnet_cidrs = [
    for i, az in local.availability_zones : 
    cidrsubnet(var.vpc_cidr, 8, i + 1)
  ]
  
  private_subnet_cidrs = [
    for i, az in local.availability_zones : 
    cidrsubnet(var.vpc_cidr, 8, i + 10)
  ]
  
  database_subnet_cidrs = [
    for i, az in local.availability_zones : 
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
  availability_zones = local.availability_zones

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
  
  # Gaming-specific VPC endpoints for cost optimization
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true
  enable_ec2_endpoint      = false

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
  create_ebs_kms_key = false  # Use default EBS encryption in dev
  
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
  
  # OIDC Provider (will be set after cluster creation)
  cluster_oidc_issuer_url = module.eks_cluster.cluster_oidc_issuer_url
  oidc_provider_arn       = module.eks_cluster.oidc_provider_arn
  
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
  private_subnet_cidrs = local.private_subnet_cidrs
  public_subnet_cidrs  = local.public_subnet_cidrs

  # Access Control (Dev-friendly - more open)
  authorized_networks   = ["0.0.0.0/0"]  # Open for dev convenience
  allowed_cidrs        = ["0.0.0.0/0"]   # Open for dev
  office_network_cidrs = var.office_network_cidrs

  # Gaming Features (all enabled for dev testing)
  enable_gaming_traffic    = true
  enable_websocket_traffic = true
  enable_public_access     = true
  enable_gaming_metrics    = true

  # Security Group Creation (minimal set for dev)
  create_database_security_group   = false  # Use default SG in dev
  create_redis_security_group     = false   # Use default SG in dev
  create_monitoring_security_group = false  # Use default SG in dev
  create_bastion_security_group   = var.create_bastion_host

  # Gaming optimizations (dev-friendly)
  gaming_optimizations = {
    enable_low_latency_rules  = true
    enable_session_affinity   = true
    enable_connection_pooling = true
    websocket_timeout        = 300    # Shorter timeout for dev
    max_connections_per_ip   = 100    # Lower limit for dev
  }

  # Environment config (relaxed for dev)
  environment_config = {
    enable_strict_security = false
    enable_debug_access   = true
    enable_admin_access   = true
    restrict_ssh_access   = false
    enable_flow_logs      = false
  }

  tags = local.common_tags
  depends_on = [module.networking]
}

# ==============================================================================
# EKS CLUSTER MODULE
# ==============================================================================

module "eks_cluster" {
  source = "../../modules/eks-cluster"

  # Basic Configuration
  project_name    = var.project_name
  environment     = local.environment
  cluster_version = var.eks_cluster_version

  # IAM Configuration
  cluster_service_role_arn = module.iam.eks_cluster_service_role_arn

  # Networking
  subnet_ids                   = concat(module.networking.private_subnet_ids, module.networking.public_subnet_ids)
  private_subnet_ids          = module.networking.private_subnet_ids
  additional_security_group_ids = [module.security_groups.eks_cluster_security_group_id]

  # Access Configuration (Dev-friendly)
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs    = ["0.0.0.0/0"]  # Open for dev

  # Encryption (using our KMS key)
  kms_key_arn = module.kms.eks_cluster_key_arn

  # Logging (minimal for dev cost optimization)
  enable_gaming_logs                     = false  # Cost optimization
  cloudwatch_log_group_retention_in_days = 3      # Minimal retention
  cloudwatch_log_group_kms_key_id       = ""      # No encryption for cost

  # EKS Addons (essential ones for gaming)
  enable_vpc_cni_addon        = true
  enable_coredns_addon        = true
  enable_kube_proxy_addon     = true
  enable_ebs_csi_driver_addon = true
  enable_efs_csi_driver_addon = false  # Not needed in dev

  # EKS Addon IAM roles
  ebs_csi_driver_role_arn = module.iam.ebs_csi_driver_role_arn

  # Gaming optimizations (dev-friendly)
  gaming_optimizations = {
    enable_prefix_delegation = true
    warm_prefix_target      = "1"
    warm_ip_target         = "5"    # Lower for dev
    minimum_ip_target      = "2"    # Lower for dev
    enable_pod_eni         = false  # Disabled for dev simplicity
    enable_fast_dns        = true
    kube_proxy_mode        = "iptables"
  }

  # Security (relaxed for dev)
  enable_gaming_traffic_rules = true
  gaming_traffic_cidrs       = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  enable_websocket_traffic   = true

  # Monitoring (disabled for dev cost optimization)
  enable_container_insights = false

  # Fargate (disabled for dev cost optimization)
  enable_fargate_profiles = false

  # Gaming namespace and service accounts
  create_gaming_namespace        = true
  create_gaming_service_account  = true
  gaming_workload_role_arn      = module.iam.gaming_workload_role_arn

  # Cluster autoscaler
  enable_cluster_autoscaler     = true
  cluster_autoscaler_role_arn  = module.iam.cluster_autoscaler_role_arn

  # Access entries (dev team access)
  platform_team_access = var.platform_team_access
  gaming_dev_team_access = var.gaming_dev_team_access

  # Environment-specific config (dev optimizations)
  environment_config = {
    enable_spot_instances    = true   # Cost optimization
    enable_gpu_nodes        = false  # Not needed in dev
    enable_arm_nodes        = false  # Not needed in dev
    max_pods_per_node       = 50     # Lower for dev
    enable_network_policies = false  # Disabled for dev simplicity
    enable_pod_security     = false  # Disabled for dev flexibility
  }

  tags = local.common_tags

  depends_on = [
    module.networking,
    module.iam,
    module.security_groups,
    module.kms
  ]
}

# ==============================================================================
# NODE GROUPS MODULE
# ==============================================================================

module "node_groups" {
  source = "../../modules/node-groups"

  # Basic Configuration
  project_name = var.project_name
  environment  = local.environment
  
  cluster_name                        = module.eks_cluster.cluster_name
  cluster_endpoint                   = module.eks_cluster.cluster_endpoint
  cluster_certificate_authority_data = module.eks_cluster.cluster_certificate_authority_data
  
  # IAM
  node_role_arn = module.iam.eks_node_group_role_arn

  # Networking
  subnet_ids          = module.networking.private_subnet_ids
  security_group_ids = [module.security_groups.eks_nodes_security_group_id]

  # Node Configuration (dev-optimized)
  node_group_version = var.eks_cluster_version
  disk_size         = 30    # Smaller for dev
  disk_type         = "gp3"
  disk_iops         = 3000
  disk_throughput   = 125
  enable_ebs_encryption = false  # Cost optimization for dev
  ebs_kms_key_id       = ""      # No encryption for dev

  # Scaling Configuration (dev-optimized)
  max_unavailable_percentage = 50  # Faster updates in dev

  # Spot Instances (enabled for dev cost optimization)
  use_spot_instances      = true
  enable_spot_node_group = true
  spot_instance_types    = ["t3.medium", "t3.large", "m5.large"]
  spot_desired_size      = 1
  spot_max_size         = 3
  spot_min_size         = 0

  # GPU and ARM nodes (disabled for dev cost optimization)
  enable_gpu_node_group = false
  enable_arm_node_group = false

  # Gaming optimizations (enabled for dev testing)
  enable_gaming_optimizations = true
  gaming_optimizations = {
    enable_low_latency        = true
    enable_enhanced_networking = true
    enable_cpu_optimizations  = true
    enable_memory_optimization = true
    enable_disk_optimization  = true
  }

  # Node labels for gaming workloads
  node_labels = {
    "gaming.io/environment"  = "dev"
    "gaming.io/cost-optimized" = "true"
    "gaming.io/workload-type" = "gaming"
  }

  # No taints in dev for flexibility
  gaming_taints = []

  # Remote access (enabled for dev debugging)
  enable_remote_access = var.enable_remote_access
  key_pair_name       = var.key_pair_name
  remote_access_security_group_ids = []

  # Monitoring (minimal for dev)
  enable_detailed_monitoring = false
  enable_container_insights = false

  # Environment overrides for dev
  environment_overrides = {
    primary_instance_types = ["t3.medium", "t3.large"]
    primary_desired_size   = 2
    primary_min_size      = 1
    primary_max_size      = 3
    enable_spot_by_default = true
  }

  tags = local.common_tags

  depends_on = [
    module.eks_cluster,
    module.iam,
    module.security_groups
  ]
}
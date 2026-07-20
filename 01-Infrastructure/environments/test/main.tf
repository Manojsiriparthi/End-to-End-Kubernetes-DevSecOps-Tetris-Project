# ==============================================================================
# TEST ENVIRONMENT - MAIN CONFIGURATION
# ==============================================================================
# Description: Test environment EKS infrastructure for Tetris gaming platform
# Environment: Test (Production-like but smaller scale, automated testing friendly)
# Author: Platform Engineering Team
# Version: 2.0.0
# ==============================================================================

terraform {
  required_version = ">= 1.5"
  
  backend "s3" {
    # Backend configuration will be provided via backend config file
    # terraform init -backend-config=backend-test.hcl
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

# Data sources for EKS authentication
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
  environment = "test"
  name_prefix = "${var.project_name}-${local.environment}"
  
  common_tags = {
    Project         = var.project_name
    Environment     = local.environment
    Owner           = var.owner
    ManagedBy      = "terraform"
    CreatedDate    = formatdate("YYYY-MM-DD", timestamp())
    CostCenter     = var.cost_center
    BusinessUnit   = var.business_unit
    BackupRequired = "true"   # Test needs backup for stability
    Compliance     = "medium" # Test has medium compliance requirements
    GamingPlatform = "tetris"
    InfrastructureType = "gaming-test"
    AutomatedTesting = "enabled"
  }

  # Availability Zones - Use 3 AZs for production-like testing
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)

  # CIDR Calculations for multi-AZ deployment (test environment)
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

  # Test-specific HA Configuration (Production-like)
  enable_dns_hostnames     = true
  enable_dns_support       = true
  enable_nat_gateway       = true
  single_nat_gateway       = false  # Multi-AZ for production-like testing
  enable_vpn_gateway       = false  # Not needed in test
  create_database_subnet_group = true

  # Security Configuration (Enhanced for testing)
  enable_flow_logs              = true   # Enable for testing monitoring
  flow_logs_retention_in_days   = 14     # Extended retention for test analysis
  
  # Gaming-specific VPC endpoints
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true
  enable_ec2_endpoint      = true  # Enhanced for testing

  tags = local.common_tags
}

# ==============================================================================
# KMS MODULE FOR ENCRYPTION
# ==============================================================================

module "kms" {
  source = "../../modules/kms"

  project_name = var.project_name
  environment  = local.environment
  aws_region   = var.aws_region

  # Key Configuration (Enhanced for production-like testing)
  create_eks_key              = true
  create_ebs_key             = true
  create_cloudwatch_logs_key = true
  create_secrets_manager_key = true
  create_s3_key              = true
  create_dynamodb_key        = true

  # Gaming-specific encryption requirements (full features for testing)
  gaming_encryption_requirements = {
    encrypt_session_data    = true
    encrypt_player_data     = true
    encrypt_game_assets     = true
    encrypt_telemetry       = true
    encrypt_backups         = true
    high_performance_mode   = false  # Test production settings
  }

  # Key Management (Test settings)
  deletion_window_in_days = 10      # Longer for test stability
  enable_key_rotation     = true    # Test production settings
  enable_multi_region     = false   # Single region for test

  # Pass IAM role ARNs from IAM module
  cluster_service_role_arn = module.iam.eks_cluster_service_role_arn
  node_group_role_arn      = module.iam.eks_node_group_role_arn
  gaming_role_arn          = module.iam.gaming_workload_role_arn

  tags = local.common_tags
  
  depends_on = [module.iam]
}

# ==============================================================================
# IAM MODULE
# ==============================================================================

module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = local.environment
  aws_region   = var.aws_region
  
  # OIDC Provider (will be set after cluster creation)
  oidc_provider_arn = module.eks_cluster.oidc_provider_arn
  
  # Service Account Roles (Full set for production-like testing)
  create_load_balancer_controller_role = true
  create_cluster_autoscaler_role      = true
  create_ebs_csi_driver_role         = true
  create_external_dns_role           = true
  create_gaming_workload_role        = true
  
  # Gaming-specific features (full features for testing)
  gaming_features = {
    enable_session_management = true
    enable_realtime_metrics  = true
    enable_auto_scaling      = true
    enable_websocket_api     = true
    enable_leaderboards      = true
  }

  # Security configuration (production-like)
  security_config = {
    max_session_duration = 7200  # Longer sessions for testing
    require_mfa         = false  # Disabled for automated testing
    external_id         = null
  }

  # Environment-specific configurations (testing-friendly)
  environment_config = {
    enable_debug_policies  = true   # Allow debugging
    enable_admin_access    = false  # More restricted than dev
    restrict_to_region     = true
    enable_cost_monitoring = true   # Monitor costs in test
  }

  # Enable additional monitoring for testing
  enable_container_insights = true

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

  # Access Control (Test-friendly but more restricted than dev)
  authorized_networks   = var.authorized_networks
  allowed_cidrs        = var.allowed_cidrs
  office_network_cidrs = var.office_network_cidrs

  # Gaming Features (all enabled for comprehensive testing)
  enable_gaming_traffic    = true
  enable_websocket_traffic = true
  enable_public_access     = true
  enable_gaming_metrics    = true

  # Security Group Creation (full set for production-like testing)
  create_database_security_group   = true
  create_redis_security_group     = true
  create_monitoring_security_group = true
  create_bastion_security_group   = var.create_bastion_host

  # Database features for testing
  enable_postgresql    = true
  enable_redis_cluster = true

  # Gaming optimizations (production-like settings)
  gaming_optimizations = {
    enable_low_latency_rules  = true
    enable_session_affinity   = true
    enable_connection_pooling = true
    websocket_timeout        = 1800   # Production-like timeout
    max_connections_per_ip   = 500    # Production-like limit
  }

  # Environment config (production-like security)
  environment_config = {
    enable_strict_security = false  # Relaxed for testing
    enable_debug_access   = true
    enable_admin_access   = false   # More restricted
    restrict_ssh_access   = true
    enable_flow_logs      = true
  }

  # Security compliance (testing requirements)
  security_compliance = {
    require_ssl                    = true
    enable_security_groups_logging = true
    restrict_default_sg           = true
    enable_nacls                  = false  # Disabled for testing simplicity
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

  # Access Configuration (Test-appropriate)
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs    = var.allowed_cidrs

  # Encryption (using our KMS key)
  kms_key_arn = module.kms.eks_cluster_key_arn

  # Logging (Enhanced for testing)
  enable_gaming_logs                     = true
  cloudwatch_log_group_retention_in_days = 14
  cloudwatch_log_group_kms_key_id       = module.kms.cloudwatch_logs_key_arn

  # EKS Addons (Full set for production-like testing)
  enable_vpc_cni_addon        = true
  enable_coredns_addon        = true
  enable_kube_proxy_addon     = true
  enable_ebs_csi_driver_addon = true
  enable_efs_csi_driver_addon = true

  # EKS Addon IAM roles
  ebs_csi_driver_role_arn = module.iam.ebs_csi_driver_role_arn
  efs_csi_driver_role_arn = module.iam.external_dns_role_arn  # Reuse for test

  # Gaming optimizations (production-like for testing)
  gaming_optimizations = {
    enable_prefix_delegation = true
    warm_prefix_target      = "1"
    warm_ip_target         = "10"
    minimum_ip_target      = "3"
    enable_pod_eni         = false
    enable_fast_dns        = true
    kube_proxy_mode        = "iptables"
  }

  # Security (production-like)
  enable_gaming_traffic_rules = true
  gaming_traffic_cidrs       = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  enable_websocket_traffic   = true

  # Monitoring (enabled for testing)
  enable_container_insights = true

  # Fargate (enabled for testing serverless capabilities)
  enable_fargate_profiles        = true
  fargate_pod_execution_role_arn = module.iam.gaming_workload_role_arn

  # Gaming namespace and service accounts
  create_gaming_namespace        = true
  create_gaming_service_account  = true
  gaming_workload_role_arn      = module.iam.gaming_workload_role_arn

  # Cluster autoscaler
  enable_cluster_autoscaler     = true
  cluster_autoscaler_role_arn  = module.iam.cluster_autoscaler_role_arn

  # Access entries (test team access)
  platform_team_access = var.platform_team_access
  gaming_dev_team_access = var.gaming_dev_team_access

  # Environment-specific config (test optimizations)
  environment_config = {
    enable_spot_instances    = true   # Mix of spot and on-demand for testing
    enable_gpu_nodes        = false  # No GPU in test environment
    enable_arm_nodes        = true   # Test ARM compatibility
    max_pods_per_node       = 110    # Production-like
    enable_network_policies = true   # Test network policies
    enable_pod_security     = true   # Test pod security
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
  
  cluster_name = module.eks_cluster.cluster_name
  node_group_role_arn = module.iam.eks_node_group_role_arn
  
  subnet_ids = {
    public   = module.networking.public_subnet_ids
    private  = module.networking.private_subnet_ids
    database = module.networking.database_subnet_ids
  }

  # Test Environment Node Groups - Production-like for validation
  node_groups = {
    # Production-like nodes for comprehensive testing
    test_gaming_nodes = {
      node_group_name = "test-gaming-nodes"
      subnet_type     = "private"
      
      instance_types = ["t3.large", "t3a.large"]
      ami_type      = "AL2023_x86_64_STANDARD"  # Modern Amazon Linux for testing
      capacity_type = "ON_DEMAND"  # Stable for testing
      
      min_size         = 2
      max_size         = 10
      desired_capacity = 3
      
      disk_size      = 100
      disk_type      = "gp3"
      disk_encrypted = true
      
      remote_access = {
        ec2_ssh_key               = ""  # No SSH access - use AWS Systems Manager
        source_security_group_ids = []
      }
      
      taints = []  # No taints for testing flexibility
      
      labels = {
        "node-type"    = "gaming"
        "network-zone" = "private"
        "workload"     = "gaming-test"
        "environment"  = "test"
        "gaming.io/testing-enabled" = "true"
      }
      
      update_config = {
        max_unavailable_percentage = 25  # Production-like
      }
      
      enable_monitoring  = true  # Enhanced monitoring for testing
      kubernetes_version = "1.33"
    }
  }

  # Security and optimization
  worker_security_group_id = module.eks_cluster.node_security_group_id
  additional_security_group_ids = [
    module.security_groups.eks_nodes_security_group_id
  ]

  enable_bootstrap_user_data = true
  kms_key_id = module.kms.ebs_key_arn

  tags = local.common_tags

  depends_on = [
    module.eks_cluster,
    module.iam,
    module.security_groups,
    module.kms
  ]
}
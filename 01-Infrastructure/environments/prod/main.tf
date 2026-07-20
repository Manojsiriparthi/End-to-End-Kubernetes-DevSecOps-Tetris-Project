# ==============================================================================
# PROD ENVIRONMENT - MAIN CONFIGURATION
# ==============================================================================
# Description: Production environment EKS infrastructure for Tetris gaming platform
# Environment: Production (Maximum availability, security, performance, disaster recovery)
# Author: Platform Engineering Team
# Version: 2.0.0
# ==============================================================================

terraform {
  required_version = ">= 1.5"
  
  backend "s3" {
    # Backend configuration will be provided via backend config file
    # terraform init -backend-config=backend-prod.hcl
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
  environment = "prod"
  name_prefix = "${var.project_name}-${local.environment}"
  
  common_tags = {
    Project         = var.project_name
    Environment     = local.environment
    Owner           = var.owner
    ManagedBy      = "terraform"
    CreatedDate    = formatdate("YYYY-MM-DD", timestamp())
    CostCenter     = var.cost_center
    BusinessUnit   = var.business_unit
    BackupRequired = "true"    # Critical for production
    Compliance     = "high"    # High compliance requirements
    GamingPlatform = "tetris"
    InfrastructureType = "gaming-production"
    CriticalWorkload = "true"
    DisasterRecovery = "enabled"
    MonitoringLevel = "enhanced"
  }

  # Availability Zones - Use all available AZs for maximum HA
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)

  # CIDR Calculations for multi-AZ deployment (production environment)
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

  # Production HA Configuration (Maximum availability)
  enable_dns_hostnames     = true
  enable_dns_support       = true
  enable_nat_gateway       = true
  single_nat_gateway       = false  # Multi-AZ NAT for HA
  enable_vpn_gateway       = var.enable_vpn_gateway  # Optional for production
  create_database_subnet_group = true

  # Security Configuration (Maximum security)
  enable_flow_logs              = true
  flow_logs_retention_in_days   = 30  # Extended retention for production
  
  # Gaming-specific VPC endpoints (all enabled for production)
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true
  enable_ec2_endpoint      = true

  # Advanced networking features for production
  manage_default_network_acl     = true
  public_dedicated_network_acl   = true
  private_dedicated_network_acl  = true
  database_dedicated_network_acl = true

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

  # Key Configuration (Full encryption for production)
  create_eks_key              = true
  create_ebs_key             = true
  create_cloudwatch_logs_key = true
  create_secrets_manager_key = true
  create_s3_key              = true
  create_dynamodb_key        = true

  # Gaming-specific encryption requirements (maximum security)
  gaming_encryption_requirements = {
    encrypt_session_data    = true
    encrypt_player_data     = true
    encrypt_game_assets     = true
    encrypt_telemetry       = true
    encrypt_backups         = true
    high_performance_mode   = false  # Security over performance
  }

  # Key Management (Production settings)
  deletion_window_in_days = 30      # Maximum retention for production
  enable_key_rotation     = true    # Mandatory for production
  enable_multi_region     = var.enable_multi_region  # Optional based on DR strategy

  # EBS encryption defaults (production security)
  set_ebs_default_key              = true
  enable_ebs_encryption_by_default = true

  # Pass IAM role ARNs from IAM module
  cluster_service_role_arn = module.iam.eks_cluster_service_role_arn
  node_group_role_arn      = module.iam.eks_node_group_role_arn
  gaming_role_arn          = module.iam.gaming_workload_role_arn

  # Security configuration (production-grade)
  security_config = {
    enable_key_grants            = true
    grant_operations            = ["Decrypt", "Encrypt", "GenerateDataKey", "ReEncryptFrom", "ReEncryptTo", "DescribeKey"]
    enable_via_service_condition = true
    allowed_services            = ["eks.amazonaws.com", "ec2.amazonaws.com", "logs.amazonaws.com", "secretsmanager.amazonaws.com", "s3.amazonaws.com", "dynamodb.amazonaws.com"]
  }

  # Environment configuration
  environment_config = {
    enable_compliance_logging = true
    require_encryption        = true
    key_rotation_interval     = 365
    backup_retention_days     = 90  # Extended for production
  }

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
  
  # Service Account Roles (Full set for production)
  create_load_balancer_controller_role = true
  create_cluster_autoscaler_role      = true
  create_ebs_csi_driver_role         = true
  create_external_dns_role           = true
  create_gaming_workload_role        = true
  
  # Gaming-specific features (all enabled for production)
  gaming_features = {
    enable_session_management = true
    enable_realtime_metrics  = true
    enable_auto_scaling      = true
    enable_websocket_api     = true
    enable_leaderboards      = true
  }

  # Security configuration (production-grade)
  security_config = {
    max_session_duration = 3600   # Standard session duration
    require_mfa         = var.require_mfa  # Optional based on security policy
    external_id         = var.external_id
  }

  # Environment-specific configurations (production-locked)
  environment_config = {
    enable_debug_policies  = false   # No debugging in production
    enable_admin_access    = false   # Restricted access
    restrict_to_region     = true
    enable_cost_monitoring = true    # Monitor costs
  }

  # Enable all monitoring for production
  enable_container_insights = true
  enable_flow_logs         = true

  # AWS services integration (full set for production)
  aws_services = {
    enable_secrets_manager = true
    enable_parameter_store = true
    enable_s3_access      = true
    enable_ses_access     = true   # For notifications
    enable_sns_access     = true
    enable_sqs_access     = true
  }

  # Cross-account access if needed
  trusted_aws_accounts = var.trusted_aws_accounts
  trusted_role_arns    = var.trusted_role_arns

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

  # Access Control (Production-secured)
  authorized_networks   = var.authorized_networks  # Restricted networks only
  allowed_cidrs        = var.allowed_cidrs         # Restricted CIDR blocks
  office_network_cidrs = var.office_network_cidrs

  # Gaming Features (all enabled for production)
  enable_gaming_traffic    = true
  enable_websocket_traffic = true
  enable_public_access     = true
  enable_gaming_metrics    = true

  # Security Group Creation (full set for production)
  create_database_security_group   = true
  create_redis_security_group     = true
  create_monitoring_security_group = true
  create_bastion_security_group   = var.create_bastion_host

  # Database features (full set for production)
  enable_postgresql    = true
  enable_redis_cluster = true

  # Gaming optimizations (production settings)
  gaming_optimizations = {
    enable_low_latency_rules  = true
    enable_session_affinity   = true
    enable_connection_pooling = true
    websocket_timeout        = 3600   # Production timeout
    max_connections_per_ip   = 1000   # Production limit
  }

  # Environment config (maximum security)
  environment_config = {
    enable_strict_security = true
    enable_debug_access   = false  # No debug access in prod
    enable_admin_access   = false  # Controlled admin access
    restrict_ssh_access   = true
    enable_flow_logs      = true
  }

  # Security compliance (maximum compliance)
  security_compliance = {
    require_ssl                    = true
    enable_security_groups_logging = true
    restrict_default_sg           = true
    enable_nacls                  = true   # Enhanced security
  }

  # Load balancer configuration (production settings)
  load_balancer_config = {
    enable_http_redirect   = true
    enable_ssl_termination = true
    enable_waf            = true   # Enable WAF for production
    custom_headers        = ["X-Frame-Options", "X-Content-Type-Options"]
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

  # Access Configuration (Production-secured)
  endpoint_private_access = true
  endpoint_public_access  = var.enable_public_access
  public_access_cidrs    = var.authorized_networks

  # Encryption (full encryption for production)
  kms_key_arn = module.kms.eks_cluster_key_arn

  # Logging (Full logging for production)
  enable_gaming_logs                     = true
  cloudwatch_log_group_retention_in_days = 30
  cloudwatch_log_group_kms_key_id       = module.kms.cloudwatch_logs_key_arn

  # EKS Addons (Full set for production)
  enable_vpc_cni_addon        = true
  enable_coredns_addon        = true
  enable_kube_proxy_addon     = true
  enable_ebs_csi_driver_addon = true
  enable_efs_csi_driver_addon = true

  # EKS Addon IAM roles
  ebs_csi_driver_role_arn = module.iam.ebs_csi_driver_role_arn
  efs_csi_driver_role_arn = module.iam.external_dns_role_arn

  # Gaming optimizations (production settings)
  gaming_optimizations = {
    enable_prefix_delegation = true
    warm_prefix_target      = "2"    # Higher for production
    warm_ip_target         = "20"   # Higher for production
    minimum_ip_target      = "5"    # Higher for production
    enable_pod_eni         = true   # Enhanced networking
    enable_fast_dns        = true
    kube_proxy_mode        = "iptables"
  }

  # Security (maximum security)
  enable_gaming_traffic_rules = true
  gaming_traffic_cidrs       = var.gaming_traffic_cidrs
  enable_websocket_traffic   = true

  # Monitoring (full monitoring for production)
  enable_container_insights = true

  # Fargate (enabled for critical workloads)
  enable_fargate_profiles        = true
  fargate_pod_execution_role_arn = module.iam.gaming_workload_role_arn

  # Gaming namespace and service accounts
  create_gaming_namespace        = true
  create_gaming_service_account  = true
  gaming_workload_role_arn      = module.iam.gaming_workload_role_arn

  # Cluster autoscaler
  enable_cluster_autoscaler     = true
  cluster_autoscaler_role_arn  = module.iam.cluster_autoscaler_role_arn

  # Access entries (controlled production access)
  platform_team_access = var.platform_team_access
  gaming_dev_team_access = []  # No dev access in production

  # Environment-specific config (production optimizations)
  environment_config = {
    enable_spot_instances    = var.enable_spot_instances  # Optional in prod
    enable_gpu_nodes        = var.enable_gpu_nodes       # Optional for advanced features
    enable_arm_nodes        = var.enable_arm_nodes       # Optional for cost optimization
    max_pods_per_node       = 110    # Maximum capacity
    enable_network_policies = true   # Required for production
    enable_pod_security     = true   # Required for production
  }

  # Cluster upgrade policy (production settings)
  cluster_upgrade_policy = {
    support_type = "EXTENDED"  # Extended support for production
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

  # Production Gaming Node Groups - Maximum Performance
  node_groups = {
    # Primary gaming nodes - Ultra-high performance
    prod_gaming_primary = {
      node_group_name = "prod-gaming-primary"
      subnet_type     = "private"
      
      instance_types = ["m5.xlarge", "c5.xlarge", "m5.2xlarge"]
      ami_type      = "BOTTLEROCKET_x86_64"  # Maximum gaming performance
      capacity_type = "ON_DEMAND"  # Stability for production
      
      min_size         = 3
      max_size         = 20
      desired_capacity = 5
      
      disk_size      = 200
      disk_type      = "gp3"
      disk_encrypted = true
      
      remote_access = {
        ec2_ssh_key               = ""  # No SSH access in production
        source_security_group_ids = []
      }
      
      taints = [{
        key    = "gaming.io/production"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
      
      labels = {
        "node-type"    = "gaming-primary"
        "network-zone" = "private"
        "workload"     = "gaming-production"
        "environment"  = "prod"
        "gaming.io/performance" = "ultra"
        "gaming.io/production-ready" = "true"
      }
      
      update_config = {
        max_unavailable_percentage = 10  # Conservative for production
      }
      
      enable_monitoring  = true
      kubernetes_version = "1.33"
    },
    
    # Secondary gaming nodes for overflow and scaling
    prod_gaming_secondary = {
      node_group_name = "prod-gaming-secondary"
      subnet_type     = "private"
      
      instance_types = ["m5.large", "c5.large", "m5.xlarge"]
      ami_type      = "BOTTLEROCKET_x86_64"  # Consistent performance
      capacity_type = "SPOT"  # Cost optimization for overflow
      
      min_size         = 0
      max_size         = 15
      desired_capacity = 2
      
      disk_size      = 100
      disk_type      = "gp3"
      disk_encrypted = true
      
      remote_access = {
        ec2_ssh_key               = ""  # No SSH access
        source_security_group_ids = []
      }
      
      taints = [{
        key    = "gaming.io/burst"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
      
      labels = {
        "node-type"    = "gaming-secondary"
        "network-zone" = "private"
        "workload"     = "gaming-overflow"
        "environment"  = "prod"
        "gaming.io/performance" = "high"
        "gaming.io/burst-capable" = "true"
      }
      
      update_config = {
        max_unavailable_percentage = 25  # Can handle more disruption
      }
      
      enable_monitoring  = true
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
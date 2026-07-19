# ==============================================================================
# EKS ADDONS - ROOT CONFIGURATION
# ==============================================================================
# Description: Universal EKS addon deployment for gaming applications
# Author: Platform Engineering Team
# Version: 1.0.0
# Gaming Features: Real-time, low-latency, auto-scaling, monitoring
# ==============================================================================

terraform {
  required_version = ">= 1.0"
  
  backend "s3" {
    # Backend configuration will be provided via backend config file
    # terraform init -backend-config=backend-{env}.hcl
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

# ==============================================================================
# DATA SOURCES FOR CLUSTER INFORMATION
# ==============================================================================

data "terraform_remote_state" "infrastructure" {
  backend = "s3"
  
  config = {
    bucket = var.infrastructure_state_bucket
    key    = var.infrastructure_state_key
    region = var.aws_region
  }
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.infrastructure.outputs.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.infrastructure.outputs.cluster_name
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

provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

# ==============================================================================
# LOCAL VALUES
# ==============================================================================

locals {
  cluster_name = data.terraform_remote_state.infrastructure.outputs.cluster_name
  
  common_tags = {
    Project         = var.project_name
    Environment     = var.environment
    Component       = "eks-addons"
    ManagedBy      = "terraform"
    GameType       = "tetris"
    ApplicationTier = "platform"
  }
  
  # Gaming-specific addon configurations
  gaming_config = {
    enable_websocket_support    = true
    enable_session_affinity     = true
    enable_real_time_metrics   = true
    enable_player_analytics    = true
    enable_auto_scaling        = true
    enable_performance_monitoring = true
  }
}

# ==============================================================================
# AWS LOAD BALANCER CONTROLLER
# ==============================================================================
# Critical for gaming: Session affinity, WebSocket support, SSL termination

module "aws_load_balancer_controller" {
  source = "./modules/aws-load-balancer-controller"
  
  cluster_name                = local.cluster_name
  cluster_oidc_issuer_url    = data.terraform_remote_state.infrastructure.outputs.cluster_oidc_issuer_url
  vpc_id                     = data.terraform_remote_state.infrastructure.outputs.vpc_id
  
  # Gaming optimizations
  enable_waf_v2              = var.environment == "prod" ? true : false
  enable_shield_advanced     = var.environment == "prod" ? true : false
  enable_websocket_support   = local.gaming_config.enable_websocket_support
  enable_session_affinity    = local.gaming_config.enable_session_affinity
  
  # Environment-specific scaling
  replica_count = var.environment == "prod" ? 3 : (var.environment == "test" ? 2 : 1)
  
  tags = local.common_tags
}

# ==============================================================================
# GATEWAY API CONTROLLER (INSTEAD OF INGRESS)
# ==============================================================================
# Modern API gateway for microservices, better than traditional ingress

module "gateway_api" {
  source = "./modules/gateway-api"
  
  cluster_name = local.cluster_name
  
  # Gaming API gateway features
  enable_rate_limiting       = true
  enable_circuit_breaker     = true
  enable_websocket_routing   = local.gaming_config.enable_websocket_support
  enable_real_time_metrics   = local.gaming_config.enable_real_time_metrics
  
  # Environment-specific configuration
  gateway_class_name = var.environment == "prod" ? "gaming-gateway-prod" : "gaming-gateway-${var.environment}"
  
  tags = local.common_tags
}

# ==============================================================================
# KARPENTER - ADVANCED NODE AUTO-SCALING
# ==============================================================================
# Better than cluster autoscaler for gaming workloads

module "karpenter" {
  source = "./modules/karpenter"
  
  cluster_name               = local.cluster_name
  cluster_oidc_issuer_url   = data.terraform_remote_state.infrastructure.outputs.cluster_oidc_issuer_url
  node_instance_profile_name = data.terraform_remote_state.infrastructure.outputs.karpenter_node_instance_profile_name
  
  # Gaming-specific node provisioning
  gaming_node_requirements = {
    cpu_architecture = ["amd64"]
    instance_categories = ["m", "c", "r"]  # Memory, Compute, Memory-optimized
    instance_generations = [4, 5, 6]       # Modern generations for performance
  }
  
  # Environment-specific scaling limits
  max_nodes_per_nodepool = var.environment == "prod" ? 100 : (var.environment == "test" ? 20 : 10)
  
  tags = local.common_tags
}

# ==============================================================================
# VERTICAL POD AUTOSCALER (VPA)
# ==============================================================================
# Right-sizing for gaming pods based on actual usage

module "vpa" {
  source = "./modules/vpa"
  
  cluster_name = local.cluster_name
  
  # Gaming workload optimization
  enable_gaming_recommendations = true
  enable_real_time_updates      = local.gaming_config.enable_real_time_metrics
  
  # VPA configuration for gaming workloads
  gaming_vpa_configs = {
    game_server = {
      min_cpu    = "100m"
      max_cpu    = "2000m"
      min_memory = "128Mi"
      max_memory = "4Gi"
    }
    websocket_handler = {
      min_cpu    = "50m"
      max_cpu    = "1000m"
      min_memory = "64Mi"
      max_memory = "2Gi"
    }
  }
  
  tags = local.common_tags
}

# ==============================================================================
# HORIZONTAL POD AUTOSCALER (HPA)
# ==============================================================================
# Player load-based scaling with custom metrics

module "hpa" {
  source = "./modules/hpa"
  
  cluster_name = local.cluster_name
  
  # Gaming-specific HPA metrics
  gaming_metrics = {
    active_connections_per_pod = 1000  # Scale when connections exceed this
    active_game_sessions_per_pod = 500 # Scale based on game sessions
    websocket_connections_per_pod = 800 # WebSocket-specific scaling
    response_time_threshold_ms = 100   # Latency-based scaling
  }
  
  # Environment-specific scaling behavior
  max_replicas = var.environment == "prod" ? 50 : (var.environment == "test" ? 10 : 5)
  min_replicas = var.environment == "prod" ? 3 : 1
  
  tags = local.common_tags
}

# ==============================================================================
# METRICS SERVER
# ==============================================================================
# Foundation for all autoscaling and monitoring

module "metrics_server" {
  source = "./modules/metrics-server"
  
  cluster_name = local.cluster_name
  
  # Gaming performance monitoring
  enable_high_frequency_metrics = local.gaming_config.enable_real_time_metrics
  metrics_resolution_seconds    = var.environment == "prod" ? 10 : 15  # Higher frequency for prod
  
  # Enhanced metrics for gaming
  gaming_metrics_config = {
    enable_network_metrics    = true
    enable_websocket_metrics  = true
    enable_session_metrics    = true
    enable_latency_metrics    = true
  }
  
  tags = local.common_tags
}

# ==============================================================================
# EBS CSI DRIVER
# ==============================================================================
# High-performance storage for game data and session state

module "ebs_csi_driver" {
  source = "./modules/ebs-csi-driver"
  
  cluster_name            = local.cluster_name
  cluster_oidc_issuer_url = data.terraform_remote_state.infrastructure.outputs.cluster_oidc_issuer_url
  
  # Gaming storage optimization
  enable_gp3_by_default          = true
  enable_fast_snapshot_restore   = var.environment == "prod"
  enable_volume_encryption       = true
  
  # Gaming-specific storage classes
  gaming_storage_classes = {
    game_data = {
      type           = "gp3"
      iops          = var.environment == "prod" ? 16000 : 8000
      throughput    = var.environment == "prod" ? 1000 : 500
      encrypted     = true
    }
    session_state = {
      type           = "io2"  # Ultra-high IOPS for session data
      iops          = var.environment == "prod" ? 32000 : 16000
      encrypted     = true
    }
  }
  
  tags = local.common_tags
}

# ==============================================================================
# EFS CSI DRIVER
# ==============================================================================
# Shared storage for game assets and configurations

module "efs_csi_driver" {
  source = "./modules/efs-csi-driver"
  
  cluster_name            = local.cluster_name
  cluster_oidc_issuer_url = data.terraform_remote_state.infrastructure.outputs.cluster_oidc_issuer_url
  
  # Gaming shared storage
  gaming_efs_configs = {
    game_assets = {
      performance_mode = var.environment == "prod" ? "maxIO" : "generalPurpose"
      throughput_mode  = var.environment == "prod" ? "provisioned" : "bursting"
      encrypted        = true
    }
  }
  
  tags = local.common_tags
}

# ==============================================================================
# EXTERNAL DNS
# ==============================================================================
# Automatic DNS management for gaming services

module "external_dns" {
  source = "./modules/external-dns"
  
  cluster_name            = local.cluster_name
  cluster_oidc_issuer_url = data.terraform_remote_state.infrastructure.outputs.cluster_oidc_issuer_url
  
  # Gaming DNS configuration
  gaming_dns_zones = var.gaming_dns_zones
  
  # Environment-specific DNS settings
  txt_owner_id = "${local.cluster_name}-external-dns"
  
  tags = local.common_tags
}

# ==============================================================================
# CLOUDWATCH CONTAINER INSIGHTS
# ==============================================================================
# Comprehensive monitoring for gaming workloads

module "cloudwatch_insights" {
  source = "./modules/cloudwatch-insights"
  
  cluster_name = local.cluster_name
  
  # Gaming monitoring features
  enable_gaming_metrics = local.gaming_config.enable_player_analytics
  enable_performance_insights = local.gaming_config.enable_performance_monitoring
  
  # Gaming-specific dashboards and alarms
  gaming_dashboards = {
    player_metrics = true
    game_performance = true
    websocket_monitoring = true
    session_analytics = true
  }
  
  # Environment-specific retention
  log_retention_days = var.environment == "prod" ? 90 : (var.environment == "test" ? 30 : 7)
  
  tags = local.common_tags
}

# ==============================================================================
# CLUSTER AUTOSCALER (BACKUP TO KARPENTER)
# ==============================================================================
# Fallback scaling solution

module "cluster_autoscaler" {
  source = "./modules/cluster-autoscaler"
  
  cluster_name            = local.cluster_name
  cluster_oidc_issuer_url = data.terraform_remote_state.infrastructure.outputs.cluster_oidc_issuer_url
  
  # Only enable if Karpenter is not available
  enabled = var.enable_cluster_autoscaler_fallback
  
  # Gaming-optimized scaling
  gaming_scaling_config = {
    scale_down_delay_after_add    = "2m"   # Fast scale-up for player spikes
    scale_down_unneeded_time      = "5m"   # Conservative scale-down
    scale_down_utilization_threshold = 0.6  # Conservative threshold for gaming
  }
  
  tags = local.common_tags
}
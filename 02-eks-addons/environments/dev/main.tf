# ==============================================================================
# EKS ADDONS - DEV ENVIRONMENT
# ==============================================================================
# Description: EKS addons deployment for development environment
# Environment: Development (Cost-optimized, gaming-friendly)
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
  }
}

# ==============================================================================
# DATA SOURCES
# ==============================================================================

# Get EKS cluster information from infrastructure layer
data "terraform_remote_state" "infrastructure" {
  backend = "s3"
  config = {
    bucket = var.infrastructure_state_bucket
    key    = var.infrastructure_state_key
    region = var.aws_region
  }
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.infrastructure.outputs.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.infrastructure.outputs.cluster_id
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

# ==============================================================================
# LOCAL VALUES
# ==============================================================================

locals {
  environment = "dev"
  cluster_name = data.terraform_remote_state.infrastructure.outputs.cluster_id
  
  common_tags = {
    Project         = var.project_name
    Environment     = local.environment
    ManagedBy      = "terraform"
    Component      = "eks-addons"
    GamingPlatform = "tetris"
    CostCenter     = var.cost_center
  }
}

# ==============================================================================
# METRICS SERVER (Essential for HPA and basic metrics)
# ==============================================================================

module "metrics_server" {
  source = "../../modules/metrics-server"
  
  cluster_name = local.cluster_name
  environment  = local.environment
  
  # Dev configuration - minimal resources
  metrics_server_config = {
    replicas = 1  # Single replica for dev
    resources = {
      requests = {
        cpu    = "50m"
        memory = "64Mi"
      }
      limits = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
  }
  
  tags = local.common_tags
}

# ==============================================================================
# AWS LOAD BALANCER CONTROLLER (Essential for gaming ALB/NLB)
# ==============================================================================

module "aws_load_balancer_controller" {
  source = "../../modules/aws-load-balancer-controller"
  
  cluster_name    = local.cluster_name
  environment     = local.environment
  oidc_provider_arn = data.terraform_remote_state.infrastructure.outputs.oidc_provider_arn
  
  # Use IAM role from infrastructure
  service_account_role_arn = data.terraform_remote_state.infrastructure.outputs.iam_roles.load_balancer_controller_role
  
  # Dev configuration - single replica
  controller_config = {
    replicas = 1
    resources = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
      limits = {
        cpu    = "200m"
        memory = "256Mi"
      }
    }
  }
  
  # Gaming-specific load balancer settings
  gaming_config = {
    enable_websocket_support = true
    enable_session_affinity  = true
    connection_idle_timeout  = 300    # 5 minutes for dev
    enable_cross_zone_load_balancing = true
  }
  
  tags = local.common_tags
  
  depends_on = [module.metrics_server]
}

# ==============================================================================
# CLUSTER AUTOSCALER (Essential for gaming workload scaling)
# ==============================================================================

module "cluster_autoscaler" {
  source = "../../modules/cluster-autoscaler"
  
  cluster_name      = local.cluster_name
  environment       = local.environment
  oidc_provider_arn = data.terraform_remote_state.infrastructure.outputs.oidc_provider_arn
  
  # Use IAM role from infrastructure
  service_account_role_arn = data.terraform_remote_state.infrastructure.outputs.iam_roles.cluster_autoscaler_role
  
  # Dev configuration - cost-optimized scaling
  autoscaler_config = {
    scale_down_delay_after_add    = "5m"   # Faster scale down for dev
    scale_down_unneeded_time      = "5m"   # Faster scale down for dev
    skip_nodes_with_local_storage = false  # Allow aggressive scaling in dev
    skip_nodes_with_system_pods   = false  # Allow aggressive scaling in dev
    
    # Gaming-specific scaling parameters
    max_node_provision_time = "10m"  # Gaming workloads need fast provisioning
    new_pod_scale_up_delay  = "30s"  # Fast scaling for player spikes
  }
  
  tags = local.common_tags
  
  depends_on = [module.metrics_server]
}

# ==============================================================================
# HORIZONTAL POD AUTOSCALER (HPA) - Essential for gaming auto-scaling
# ==============================================================================

module "hpa" {
  source = "../../modules/hpa"
  
  cluster_name = local.cluster_name
  environment  = local.environment
  
  # Gaming-specific HPA configurations
  gaming_hpa_configs = {
    tetris_backend = {
      namespace = "gaming"
      deployment_name = "tetris-backend"
      min_replicas = 2
      max_replicas = 10    # Limited scale for dev
      target_cpu_percent = 70
      
      # Gaming-specific metrics
      custom_metrics = [
        {
          name = "websocket_connections_per_pod"
          target_value = 100  # Scale when >100 connections per pod
        }
      ]
    }
    
    tetris_websocket = {
      namespace = "gaming"
      deployment_name = "tetris-websocket"
      min_replicas = 1
      max_replicas = 5     # Limited scale for dev
      target_cpu_percent = 60  # Lower threshold for real-time services
      
      custom_metrics = [
        {
          name = "active_game_sessions"
          target_value = 50  # Scale when >50 active sessions per pod
        }
      ]
    }
  }
  
  tags = local.common_tags
  
  depends_on = [module.metrics_server]
}

# ==============================================================================
# EBS CSI DRIVER (Essential for persistent storage)
# ==============================================================================

module "ebs_csi_driver" {
  source = "../../modules/ebs-csi-driver"
  
  cluster_name      = local.cluster_name
  environment       = local.environment
  oidc_provider_arn = data.terraform_remote_state.infrastructure.outputs.oidc_provider_arn
  
  # Use IAM role from infrastructure
  service_account_role_arn = data.terraform_remote_state.infrastructure.outputs.iam_roles.ebs_csi_driver_role
  
  # Dev configuration
  ebs_csi_config = {
    controller_replicas = 1  # Single replica for dev
    enable_volume_scheduling = true
    enable_volume_resizing = true
    
    # Gaming-specific storage configurations
    default_storage_class = {
      name = "gaming-gp3"
      type = "gp3"
      iops = 3000
      throughput = 125
      encrypted = false  # Disabled for dev cost optimization
    }
    
    gaming_storage_classes = [
      {
        name = "gaming-fast"
        type = "gp3"
        iops = 4000
        throughput = 250
        description = "Fast storage for gaming databases"
      }
    ]
  }
  
  tags = local.common_tags
  
  depends_on = [module.metrics_server]
}

# ==============================================================================
# CLOUDWATCH LOGS (Minimal logging for dev)
# ==============================================================================

module "cloudwatch_logs" {
  source = "../../modules/cloudwatch-logs"
  
  cluster_name = local.cluster_name
  environment  = local.environment
  
  # Dev configuration - minimal logging
  logging_config = {
    log_group_retention_days = 3  # Short retention for cost optimization
    
    # Gaming application logs
    gaming_log_groups = [
      {
        name = "/aws/gaming/tetris-backend"
        retention_days = 3
      },
      {
        name = "/aws/gaming/tetris-websocket"
        retention_days = 3
      }
    ]
    
    # Fluent Bit configuration for gaming logs
    fluent_bit_config = {
      enabled = false  # Disabled for dev cost optimization
      resources = {
        requests = {
          cpu = "50m"
          memory = "64Mi"
        }
      }
    }
  }
  
  tags = local.common_tags
}

# ==============================================================================
# EXTERNAL DNS (Disabled for dev)
# ==============================================================================

# Commented out for dev environment to reduce costs
# module "external_dns" {
#   source = "../../modules/external-dns"
#   
#   cluster_name      = local.cluster_name
#   environment       = local.environment
#   oidc_provider_arn = data.terraform_remote_state.infrastructure.outputs.oidc_provider_arn
#   
#   service_account_role_arn = data.terraform_remote_state.infrastructure.outputs.iam_roles.external_dns_role
#   
#   tags = local.common_tags
# }

# ==============================================================================
# KARPENTER (Disabled for dev - using Cluster Autoscaler instead)
# ==============================================================================

# Commented out for dev environment to reduce complexity
# module "karpenter" {
#   source = "../../modules/karpenter"
#   
#   cluster_name = local.cluster_name
#   environment  = local.environment
#   
#   tags = local.common_tags
# }

# ==============================================================================
# VERTICAL POD AUTOSCALER (VPA) - Disabled for dev
# ==============================================================================

# Commented out for dev environment to reduce resource usage
# module "vpa" {
#   source = "../../modules/vpa"
#   
#   cluster_name = local.cluster_name
#   environment  = local.environment
#   
#   tags = local.common_tags
# }

# ==============================================================================
# GATEWAY API (Disabled for dev - using traditional Ingress)
# ==============================================================================

# Commented out for dev environment - using ALB Ingress Controller instead
# module "gateway_api" {
#   source = "../../modules/gateway-api"
#   
#   cluster_name = local.cluster_name
#   environment  = local.environment
#   
#   tags = local.common_tags
# }
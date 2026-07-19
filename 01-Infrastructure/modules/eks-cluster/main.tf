# ==============================================================================
# EKS CLUSTER MODULE - MAIN CONFIGURATION
# ==============================================================================
# Description: Comprehensive EKS cluster for real-time gaming applications
# Features: Gaming-optimized configuration, auto-scaling, security, monitoring
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

terraform {
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
# LOCAL VALUES
# ==============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = merge(var.tags, {
    Component = "eks"
    Module    = "cluster"
  })

  # Gaming-specific cluster configuration
  gaming_cluster_config = {
    # Real-time gaming requires low latency
    enable_pod_identity = true
    enable_cluster_creator_admin_permissions = true
    
    # Gaming workloads often need custom networking
    cluster_ip_family = "ipv4"
    
    # Security for gaming infrastructure
    cluster_encryption_config_enable = true
    cluster_encryption_config_kms_key_deletion_window_in_days = var.kms_key_deletion_window
    
    # Logging for game analytics
    cluster_enabled_log_types = var.enable_gaming_logs ? [
      "api", 
      "audit", 
      "authenticator", 
      "controllerManager", 
      "scheduler"
    ] : ["api", "audit"]
    
    # Access control for gaming teams
    authentication_mode = "API_AND_CONFIG_MAP"
  }
}

# ==============================================================================
# DATA SOURCES
# ==============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

# ==============================================================================
# EKS CLUSTER
# ==============================================================================

resource "aws_eks_cluster" "main" {
  name     = local.name_prefix
  role_arn = var.cluster_service_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
    security_group_ids      = var.additional_security_group_ids
  }

  # Gaming clusters need encryption for player data security
  dynamic "encryption_config" {
    for_each = var.kms_key_arn != "" ? [1] : []
    content {
      provider {
        key_arn = var.kms_key_arn
      }
      resources = ["secrets"]
    }
  }

  # Enable comprehensive logging for gaming analytics
  enabled_cluster_log_types = local.gaming_cluster_config.cluster_enabled_log_types

  # Access configuration for gaming teams
  access_config {
    authentication_mode                         = local.gaming_cluster_config.authentication_mode
    bootstrap_cluster_creator_admin_permissions = local.gaming_cluster_config.enable_cluster_creator_admin_permissions
  }

  # Upgrade policy for gaming infrastructure
  dynamic "upgrade_policy" {
    for_each = var.cluster_upgrade_policy.support_type != null ? [1] : []
    content {
      support_type = var.cluster_upgrade_policy.support_type
    }
  }

  # Ensure proper dependencies
  depends_on = [
    aws_cloudwatch_log_group.cluster
  ]

  tags = merge(local.common_tags, {
    Name = local.name_prefix
    "kubernetes.io/cluster/${local.name_prefix}" = "owned"
    Purpose = "Gaming application cluster"
  })
}

# ==============================================================================
# OIDC IDENTITY PROVIDER
# ==============================================================================

data "tls_certificate" "cluster_oidc_issuer_url" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster_oidc_issuer_url.certificates[0].sha1_fingerprint]
  url            = aws_eks_cluster.main.identity[0].oidc[0].issuer
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-oidc-provider"
  })
}

# ==============================================================================
# CLOUDWATCH LOG GROUP
# ==============================================================================

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${local.name_prefix}/cluster"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cluster-logs"
  })
}

# ==============================================================================
# EKS ADDONS
# ==============================================================================

# VPC CNI addon for network performance (critical for gaming)
resource "aws_eks_addon" "vpc_cni" {
  count = var.enable_vpc_cni_addon ? 1 : 0
  
  cluster_name             = aws_eks_cluster.main.name
  addon_name              = "vpc-cni"
  addon_version           = var.vpc_cni_addon_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  
  configuration_values = jsonencode({
    env = {
      # Gaming optimization: Enable prefix delegation for more IPs per node
      ENABLE_PREFIX_DELEGATION = var.gaming_optimizations.enable_prefix_delegation ? "true" : "false"
      WARM_PREFIX_TARGET      = var.gaming_optimizations.warm_prefix_target
      WARM_IP_TARGET          = var.gaming_optimizations.warm_ip_target
      MINIMUM_IP_TARGET       = var.gaming_optimizations.minimum_ip_target
      # Network performance optimization
      ENABLE_POD_ENI          = var.gaming_optimizations.enable_pod_eni ? "true" : "false"
    }
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc-cni"
  })

  depends_on = [aws_eks_cluster.main]
}

# CoreDNS addon for service discovery
resource "aws_eks_addon" "coredns" {
  count = var.enable_coredns_addon ? 1 : 0
  
  cluster_name             = aws_eks_cluster.main.name
  addon_name              = "coredns"
  addon_version           = var.coredns_addon_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  configuration_values = jsonencode({
    # Gaming optimization: Faster DNS resolution
    corefile = var.gaming_optimizations.enable_fast_dns ? {
      ".:53" = {
        errors = true
        health = {
          lameduck = "5s"
        }
        ready = true
        kubernetes = {
          "cluster.local" = {
            "in-addr.arpa" = true
            "ip6.arpa" = true
          }
          fallthrough = ["in-addr.arpa", "ip6.arpa"]
        }
        prometheus = ":9153"
        forward = ". 169.254.169.253"
        cache = 30
        loop = true
        reload = true
        loadbalance = true
      }
    } : {}
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-coredns"
  })

  depends_on = [aws_eks_cluster.main]
}

# Kube-proxy addon for network rules
resource "aws_eks_addon" "kube_proxy" {
  count = var.enable_kube_proxy_addon ? 1 : 0
  
  cluster_name             = aws_eks_cluster.main.name
  addon_name              = "kube-proxy"
  addon_version           = var.kube_proxy_addon_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  configuration_values = jsonencode({
    # Gaming optimization: iptables mode for better performance
    mode = var.gaming_optimizations.kube_proxy_mode
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-kube-proxy"
  })

  depends_on = [aws_eks_cluster.main]
}

# EBS CSI Driver for persistent storage
resource "aws_eks_addon" "ebs_csi_driver" {
  count = var.enable_ebs_csi_driver_addon ? 1 : 0
  
  cluster_name             = aws_eks_cluster.main.name
  addon_name              = "aws-ebs-csi-driver"
  addon_version           = var.ebs_csi_driver_addon_version
  service_account_role_arn = var.ebs_csi_driver_role_arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  configuration_values = jsonencode({
    controller = {
      # Gaming optimization: Enable volume scheduling for anti-affinity
      extraArgs = [
        "--enable-volume-scheduling=true",
        "--enable-volume-resizing=true"
      ]
    }
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ebs-csi-driver"
  })

  depends_on = [aws_eks_cluster.main]
}

# EFS CSI Driver for shared storage (game assets, logs)
resource "aws_eks_addon" "efs_csi_driver" {
  count = var.enable_efs_csi_driver_addon ? 1 : 0
  
  cluster_name             = aws_eks_cluster.main.name
  addon_name              = "aws-efs-csi-driver"
  addon_version           = var.efs_csi_driver_addon_version
  service_account_role_arn = var.efs_csi_driver_role_arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-efs-csi-driver"
  })

  depends_on = [aws_eks_cluster.main]
}

# ==============================================================================
# ACCESS ENTRIES FOR GAMING TEAMS
# ==============================================================================

# Platform team access
resource "aws_eks_access_entry" "platform_team" {
  count = length(var.platform_team_access)
  
  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = var.platform_team_access[count.index].principal_arn
  kubernetes_groups = var.platform_team_access[count.index].kubernetes_groups
  type             = var.platform_team_access[count.index].type

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-platform-access-${count.index}"
    Team = "platform"
  })
}

# Gaming development team access
resource "aws_eks_access_entry" "gaming_dev_team" {
  count = length(var.gaming_dev_team_access)
  
  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = var.gaming_dev_team_access[count.index].principal_arn
  kubernetes_groups = var.gaming_dev_team_access[count.index].kubernetes_groups
  type             = var.gaming_dev_team_access[count.index].type

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-gaming-dev-access-${count.index}"
    Team = "gaming-development"
  })
}

# ==============================================================================
# CLUSTER SECURITY GROUP RULES
# ==============================================================================

# Allow gaming-specific traffic
resource "aws_security_group_rule" "cluster_gaming_ingress" {
  count = var.enable_gaming_traffic_rules ? 1 : 0
  
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = var.gaming_traffic_cidrs
  security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  description       = "Allow gaming traffic from specified CIDRs"
}

# WebSocket traffic for real-time gaming
resource "aws_security_group_rule" "cluster_websocket_ingress" {
  count = var.enable_websocket_traffic ? 1 : 0
  
  type              = "ingress"
  from_port         = 8080
  to_port           = 8090
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  description       = "Allow WebSocket traffic for real-time gaming"
}

# ==============================================================================
# MONITORING AND OBSERVABILITY
# ==============================================================================

# CloudWatch Container Insights
resource "aws_eks_cluster_auth" "cluster" {
  count = var.enable_container_insights ? 1 : 0
  name  = aws_eks_cluster.main.name
}

# ==============================================================================
# FARGATE PROFILES (for gaming workloads that need serverless compute)
# ==============================================================================

resource "aws_eks_fargate_profile" "gaming_workloads" {
  count = var.enable_fargate_profiles ? 1 : 0
  
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "${local.name_prefix}-gaming-fargate"
  pod_execution_role_arn = var.fargate_pod_execution_role_arn
  subnet_ids             = var.private_subnet_ids

  selector {
    namespace = "gaming"
    labels = {
      "compute-type" = "fargate"
    }
  }

  selector {
    namespace = "gaming-system"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-gaming-fargate"
    Purpose = "Gaming workloads serverless compute"
  })

  depends_on = [aws_eks_cluster.main]
}

# ==============================================================================
# GAMING-SPECIFIC CONFIGURATIONS
# ==============================================================================

# Create namespace for gaming applications
resource "kubernetes_namespace" "gaming" {
  count = var.create_gaming_namespace ? 1 : 0
  
  metadata {
    name = "gaming"
    labels = {
      "name" = "gaming"
      "environment" = var.environment
      "gaming.io/managed-by" = "terraform"
    }
    annotations = {
      "gaming.io/description" = "Namespace for Tetris and other gaming applications"
      "gaming.io/team" = "platform-engineering"
    }
  }

  depends_on = [aws_eks_cluster.main]
}

# Create service account for gaming workloads
resource "kubernetes_service_account" "gaming_workload" {
  count = var.create_gaming_service_account ? 1 : 0
  
  metadata {
    name      = "tetris-app"
    namespace = var.create_gaming_namespace ? kubernetes_namespace.gaming[0].metadata[0].name : "gaming"
    annotations = {
      "eks.amazonaws.com/role-arn" = var.gaming_workload_role_arn
    }
  }

  depends_on = [kubernetes_namespace.gaming]
}

# ==============================================================================
# CLUSTER AUTOSCALER CONFIGURATION
# ==============================================================================

# Service account for cluster autoscaler
resource "kubernetes_service_account" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0
  
  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "k8s-app"   = "cluster-autoscaler"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = var.cluster_autoscaler_role_arn
    }
  }

  depends_on = [aws_eks_cluster.main]
}
# ==============================================================================
# TEST ENVIRONMENT - OUTPUTS
# ==============================================================================
# Description: Output values for test environment
# Environment: Test (Production-like but smaller scale)
# Author: Platform Engineering Team
# Version: 2.0.0
# ==============================================================================

# ==============================================================================
# ENVIRONMENT INFORMATION
# ==============================================================================

output "environment" {
  description = "Environment name"
  value       = local.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "name_prefix" {
  description = "Name prefix used for all resources"
  value       = local.name_prefix
}

# ==============================================================================
# NETWORKING OUTPUTS
# ==============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.networking.database_subnet_ids
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = module.networking.nat_gateway_ids
}

# ==============================================================================
# EKS CLUSTER OUTPUTS
# ==============================================================================

output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks_cluster.cluster_id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks_cluster.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks_cluster.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks_cluster.cluster_security_group_id
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.eks_cluster.cluster_identity_oidc_issuer
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider for the EKS cluster"
  value       = module.eks_cluster.oidc_provider_arn
}

# ==============================================================================
# NODE GROUPS OUTPUTS
# ==============================================================================

output "node_groups_summary" {
  description = "Summary of all node groups"
  value       = module.node_groups.node_groups_summary
}

output "gaming_infrastructure_summary" {
  description = "Summary of gaming infrastructure configuration"
  value       = module.node_groups.gaming_infrastructure_summary
}

# ==============================================================================
# SECURITY OUTPUTS
# ==============================================================================

output "security_group_mappings" {
  description = "Map of security group names to IDs"
  value       = module.security_groups.security_group_mappings
}

output "kms_key_mappings" {
  description = "Map of KMS key purposes to ARNs"
  value       = module.kms.key_mappings
}

# ==============================================================================
# IAM OUTPUTS
# ==============================================================================

output "iam_roles" {
  description = "Map of IAM role names to ARNs"
  value = {
    eks_cluster_service_role = module.iam.eks_cluster_service_role_arn
    eks_node_group_role     = module.iam.eks_node_group_role_arn
    gaming_workload_role    = module.iam.gaming_workload_role_arn
  }
}

output "service_account_annotations" {
  description = "Annotations for Kubernetes service accounts"
  value       = module.iam.service_account_annotations
}

# ==============================================================================
# KUBECTL CONFIGURATION
# ==============================================================================

output "kubectl_config" {
  description = "kubectl configuration for connecting to the cluster"
  value       = module.eks_cluster.kubectl_config
  sensitive   = true
}

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks_cluster.cluster_name}"
}

# ==============================================================================
# GAMING PLATFORM OUTPUTS
# ==============================================================================

output "gaming_namespace" {
  description = "Gaming namespace information"
  value       = module.eks_cluster.gaming_namespace
}

output "gaming_service_account" {
  description = "Gaming service account information"
  value       = module.eks_cluster.gaming_service_account
}

output "websocket_endpoints" {
  description = "WebSocket endpoints for real-time gaming"
  value = {
    internal_lb = "ws://${module.eks_cluster.cluster_name}-internal.${var.aws_region}.elb.amazonaws.com:8080"
    # External LB endpoint would be configured post-deployment
  }
}

# ==============================================================================
# MONITORING AND OBSERVABILITY
# ==============================================================================

output "cloudwatch_log_groups" {
  description = "CloudWatch log groups"
  value = {
    cluster_logs = module.eks_cluster.cloudwatch_log_group_name
  }
}

output "monitoring_endpoints" {
  description = "Monitoring and metrics endpoints"
  value = {
    prometheus_endpoint = "http://prometheus.monitoring.svc.cluster.local:9090"
    grafana_endpoint   = "http://grafana.monitoring.svc.cluster.local:3000"
  }
}

# ==============================================================================
# TEST ENVIRONMENT SPECIFIC
# ==============================================================================

output "test_environment_summary" {
  description = "Summary of test environment configuration"
  value = {
    environment_type          = "test"
    cluster_name             = module.eks_cluster.cluster_name
    cluster_version          = var.eks_cluster_version
    total_availability_zones = length(local.availability_zones)
    cost_optimizations = {
      spot_instances_enabled = var.enable_spot_instances
      arm_nodes_enabled     = var.enable_arm_nodes
      single_nat_gateway    = false  # Multi-AZ for production-like testing
    }
    testing_features = {
      remote_access_enabled   = var.enable_remote_access
      bastion_host_created   = var.create_bastion_host
      enhanced_monitoring    = true
      fargate_enabled        = true
    }
    gaming_configuration = {
      websocket_support      = true
      real_time_metrics     = true
      session_affinity      = true
      low_latency_optimized = true
    }
  }
}

# ==============================================================================
# DEPLOYMENT INFORMATION
# ==============================================================================

output "deployment_info" {
  description = "Information for application deployment"
  value = {
    cluster_name              = module.eks_cluster.cluster_name
    cluster_endpoint         = module.eks_cluster.cluster_endpoint
    gaming_namespace         = module.eks_cluster.gaming_namespace != null ? module.eks_cluster.gaming_namespace.name : null
    gaming_service_account   = module.eks_cluster.gaming_service_account != null ? module.eks_cluster.gaming_service_account.name : null
    load_balancer_role_arn   = module.iam.aws_load_balancer_controller_role_arn
    cluster_autoscaler_role_arn = module.iam.cluster_autoscaler_role_arn
    gaming_workload_role_arn = module.iam.gaming_workload_role_arn
  }
}

# ==============================================================================
# SECURITY SUMMARY
# ==============================================================================

output "security_summary" {
  description = "Security configuration summary"
  value = {
    encryption_enabled = {
      eks_secrets = module.kms.eks_cluster_key_arn != null
      ebs_volumes = module.kms.ebs_key_arn != null
      cloudwatch_logs = module.kms.cloudwatch_logs_key_arn != null
      s3_buckets = module.kms.s3_key_arn != null
    }
    network_security = {
      private_cluster_endpoint = !var.enable_public_access
      authorized_networks_configured = length(var.authorized_networks) > 0
      security_groups_configured = length(module.security_groups.security_group_mappings) > 0
      vpc_flow_logs_enabled = true
    }
    access_control = {
      rbac_enabled = true
      pod_security_enabled = true
      network_policies_enabled = true
      service_accounts_created = length(module.iam.service_account_annotations) > 0
    }
  }
}
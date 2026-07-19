# ==============================================================================
# PROD ENVIRONMENT - OUTPUTS
# ==============================================================================
# Description: Output values for production environment
# Environment: Production (Maximum availability, security, performance)
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

output "availability_zones" {
  description = "Availability zones used"
  value       = local.availability_zones
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
  sensitive   = true  # Sensitive in production
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = module.eks_cluster.cluster_version
}

output "cluster_status" {
  description = "EKS cluster status"
  value       = module.eks_cluster.cluster_status
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

output "total_capacity_summary" {
  description = "Total compute capacity across all node groups"
  value       = module.node_groups.total_capacity_summary
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

output "encryption_summary" {
  description = "Encryption configuration summary"
  value       = module.kms.gaming_encryption_summary
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
    load_balancer_controller_role = module.iam.aws_load_balancer_controller_role_arn
    cluster_autoscaler_role = module.iam.cluster_autoscaler_role_arn
    external_dns_role      = module.iam.external_dns_role_arn
  }
}

output "service_account_annotations" {
  description = "Annotations for Kubernetes service accounts"
  value       = module.iam.service_account_annotations
  sensitive   = true  # Contains role ARNs
}

# ==============================================================================
# KUBECTL CONFIGURATION (RESTRICTED OUTPUT)
# ==============================================================================

output "kubeconfig_command" {
  description = "Command to configure kubectl (admin access required)"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks_cluster.cluster_name}"
}

# Note: kubectl_config output is omitted in production for security
# Cluster access should be managed through proper IAM and RBAC

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

output "gaming_endpoints" {
  description = "Gaming platform endpoints (internal)"
  value = {
    # Production endpoints should be configured via Load Balancer Controller
    # after deployment with proper domain names and SSL certificates
    cluster_internal_endpoint = "https://${module.eks_cluster.cluster_name}.${var.aws_region}.eks.amazonaws.com"
    websocket_service_namespace = module.eks_cluster.gaming_namespace != null ? module.eks_cluster.gaming_namespace.name : "gaming"
  }
  sensitive = true
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

output "monitoring_configuration" {
  description = "Monitoring configuration details"
  value = {
    container_insights_enabled = true
    enhanced_monitoring_enabled = true
    log_retention_days = 30
    metrics_collection_interval = 60
  }
}

# ==============================================================================
# PRODUCTION ENVIRONMENT SPECIFIC
# ==============================================================================

output "production_environment_summary" {
  description = "Summary of production environment configuration"
  value = {
    environment_type = "production"
    cluster_name    = module.eks_cluster.cluster_name
    cluster_version = var.eks_cluster_version
    high_availability = {
      multi_az_deployment    = length(local.availability_zones) >= 3
      multi_nat_gateways    = length(module.networking.nat_gateway_ids) > 1
      cross_region_backups  = var.enable_cross_region_backup
    }
    security_features = {
      encryption_at_rest     = true
      encryption_in_transit  = true
      network_policies      = true
      pod_security_policies = true
      private_endpoints     = !var.enable_public_access
      mfa_required         = var.require_mfa
    }
    performance_features = {
      performance_tier          = var.performance_tier
      auto_scaling_enabled     = true
      spot_instances_enabled   = var.enable_spot_instances
      gpu_nodes_enabled        = var.enable_gpu_nodes
      arm_nodes_enabled        = var.enable_arm_nodes
      enhanced_networking      = true
    }
    compliance_features = {
      framework           = var.compliance_framework
      audit_logging      = var.enable_audit_logging
      data_residency     = var.data_residency_requirements
      backup_retention   = var.backup_retention_days
    }
    gaming_configuration = {
      max_concurrent_players   = 50000
      low_latency_optimized   = true
      session_affinity        = true
      websocket_support       = true
      real_time_metrics      = true
      anti_cheat_monitoring  = true
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
    cluster_endpoint         = "REQUIRES_AUTHENTICATION"  # Don't expose in output
    gaming_namespace         = module.eks_cluster.gaming_namespace != null ? module.eks_cluster.gaming_namespace.name : null
    gaming_service_account   = module.eks_cluster.gaming_service_account != null ? module.eks_cluster.gaming_service_account.name : null
    
    # Service account role ARNs for workload identity
    load_balancer_role_arn   = module.iam.aws_load_balancer_controller_role_arn
    cluster_autoscaler_role_arn = module.iam.cluster_autoscaler_role_arn
    gaming_workload_role_arn = module.iam.gaming_workload_role_arn
    external_dns_role_arn    = module.iam.external_dns_role_arn
    
    # Network configuration
    vpc_id               = module.networking.vpc_id
    private_subnet_ids   = module.networking.private_subnet_ids
    public_subnet_ids    = module.networking.public_subnet_ids
    
    # Security configuration
    security_groups = {
      cluster_sg  = module.security_groups.eks_cluster_security_group_id
      nodes_sg    = module.security_groups.eks_nodes_security_group_id
      gaming_sg   = module.security_groups.gaming_app_security_group_id
      alb_sg      = module.security_groups.alb_security_group_id
    }
  }
  sensitive = true  # Contains deployment-sensitive information
}

# ==============================================================================
# DISASTER RECOVERY INFORMATION
# ==============================================================================

output "disaster_recovery_info" {
  description = "Disaster recovery configuration"
  value = {
    backup_enabled           = var.enable_cross_region_backup
    backup_retention_days   = var.backup_retention_days
    multi_region_keys       = var.enable_multi_region
    availability_zones      = length(local.availability_zones)
    nat_gateway_redundancy  = length(module.networking.nat_gateway_ids) > 1
    
    recovery_procedures = {
      cluster_backup     = "EKS cluster configuration is stored in Terraform state"
      persistent_volumes = "EBS volumes have automated snapshots enabled"
      application_data   = "Application data backup via Velero (to be configured)"
      secrets_backup     = "Secrets are stored in AWS Secrets Manager with encryption"
    }
  }
}

# ==============================================================================
# COST OPTIMIZATION INFORMATION
# ==============================================================================

output "cost_optimization_summary" {
  description = "Cost optimization features and estimates"
  value = {
    optimization_features = {
      spot_instances_enabled    = var.enable_spot_instances
      arm_nodes_enabled        = var.enable_arm_nodes
      auto_scaling_enabled     = true
      single_nat_gateway       = false  # Multi-AZ for HA
    }
    
    estimated_monthly_costs = {
      # These are rough estimates - actual costs will vary
      eks_cluster_hours       = 24 * 30 * 0.10  # $73/month
      nat_gateway_hours       = length(module.networking.nat_gateway_ids) * 24 * 30 * 0.045
      # Node costs depend on instance types and scaling
      notes = "Actual costs depend on usage patterns, instance types, and data transfer"
    }
    
    cost_monitoring = {
      billing_alerts_enabled = true
      cost_allocation_tags   = true
      resource_tagging      = "comprehensive"
    }
  }
}

# ==============================================================================
# OPERATIONAL INFORMATION
# ==============================================================================

output "operational_info" {
  description = "Operational information for production management"
  value = {
    maintenance_windows = {
      preferred_maintenance_day  = "Sunday"
      preferred_maintenance_time = "02:00 UTC"
      auto_minor_version_upgrade = false  # Controlled upgrades in production
    }
    
    scaling_configuration = {
      cluster_autoscaler_enabled = true
      hpa_enabled               = true  # Horizontal Pod Autoscaler
      vpa_enabled               = false # Vertical Pod Autoscaler (optional)
      target_cpu_utilization    = var.auto_scaling_target_cpu
    }
    
    networking_details = {
      vpc_endpoints_enabled     = true
      private_link_enabled     = false  # Optional for enhanced security
      transit_gateway_enabled  = false  # Optional for multi-VPC connectivity
    }
    
    security_operations = {
      security_scanning_enabled = true
      vulnerability_assessments = "monthly"
      penetration_testing      = "quarterly"
      security_audit_frequency = "annual"
    }
  }
}
# ==============================================================================
# IAM MODULE - OUTPUTS
# ==============================================================================
# Description: Output values for IAM module
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

# ==============================================================================
# EKS CLUSTER ROLE OUTPUTS
# ==============================================================================

output "eks_cluster_service_role_arn" {
  description = "ARN of the EKS cluster service role"
  value       = aws_iam_role.eks_cluster_service_role.arn
}

output "eks_cluster_service_role_name" {
  description = "Name of the EKS cluster service role"
  value       = aws_iam_role.eks_cluster_service_role.name
}

output "eks_cluster_service_role_unique_id" {
  description = "Unique ID of the EKS cluster service role"
  value       = aws_iam_role.eks_cluster_service_role.unique_id
}

# ==============================================================================
# EKS NODE GROUP ROLE OUTPUTS
# ==============================================================================

output "eks_node_group_role_arn" {
  description = "ARN of the EKS node group role"
  value       = aws_iam_role.eks_node_group_role.arn
}

output "eks_node_group_role_name" {
  description = "Name of the EKS node group role"
  value       = aws_iam_role.eks_node_group_role.name
}

output "eks_node_group_role_unique_id" {
  description = "Unique ID of the EKS node group role"
  value       = aws_iam_role.eks_node_group_role.unique_id
}

output "eks_node_group_instance_profile_name" {
  description = "Name of the EKS node group instance profile"
  value       = aws_iam_instance_profile.eks_node_group_instance_profile.name
}

output "eks_node_group_instance_profile_arn" {
  description = "ARN of the EKS node group instance profile"
  value       = aws_iam_instance_profile.eks_node_group_instance_profile.arn
}

# ==============================================================================
# AWS LOAD BALANCER CONTROLLER OUTPUTS
# ==============================================================================

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller role"
  value       = var.create_load_balancer_controller_role ? aws_iam_role.aws_load_balancer_controller_role[0].arn : null
}

output "aws_load_balancer_controller_role_name" {
  description = "Name of the AWS Load Balancer Controller role"
  value       = var.create_load_balancer_controller_role ? aws_iam_role.aws_load_balancer_controller_role[0].name : null
}

output "aws_load_balancer_controller_policy_arn" {
  description = "ARN of the AWS Load Balancer Controller policy"
  value       = var.create_load_balancer_controller_role ? aws_iam_policy.aws_load_balancer_controller_policy[0].arn : null
}

# ==============================================================================
# CLUSTER AUTOSCALER OUTPUTS
# ==============================================================================

output "cluster_autoscaler_role_arn" {
  description = "ARN of the Cluster Autoscaler role"
  value       = var.create_cluster_autoscaler_role ? aws_iam_role.cluster_autoscaler_role[0].arn : null
}

output "cluster_autoscaler_role_name" {
  description = "Name of the Cluster Autoscaler role"
  value       = var.create_cluster_autoscaler_role ? aws_iam_role.cluster_autoscaler_role[0].name : null
}

output "cluster_autoscaler_policy_arn" {
  description = "ARN of the Cluster Autoscaler policy"
  value       = var.create_cluster_autoscaler_role ? aws_iam_policy.cluster_autoscaler_policy[0].arn : null
}

# ==============================================================================
# EBS CSI DRIVER OUTPUTS
# ==============================================================================

output "ebs_csi_driver_role_arn" {
  description = "ARN of the EBS CSI Driver role"
  value       = var.create_ebs_csi_driver_role ? aws_iam_role.ebs_csi_driver_role[0].arn : null
}

output "ebs_csi_driver_role_name" {
  description = "Name of the EBS CSI Driver role"
  value       = var.create_ebs_csi_driver_role ? aws_iam_role.ebs_csi_driver_role[0].name : null
}

# ==============================================================================
# EXTERNAL DNS OUTPUTS
# ==============================================================================

output "external_dns_role_arn" {
  description = "ARN of the External DNS role"
  value       = var.create_external_dns_role ? aws_iam_role.external_dns_role[0].arn : null
}

output "external_dns_role_name" {
  description = "Name of the External DNS role"
  value       = var.create_external_dns_role ? aws_iam_role.external_dns_role[0].name : null
}

output "external_dns_policy_arn" {
  description = "ARN of the External DNS policy"
  value       = var.create_external_dns_role ? aws_iam_policy.external_dns_policy[0].arn : null
}

# ==============================================================================
# GAMING WORKLOAD OUTPUTS
# ==============================================================================

output "gaming_workload_role_arn" {
  description = "ARN of the gaming workload role"
  value       = var.create_gaming_workload_role ? aws_iam_role.gaming_workload_role[0].arn : null
}

output "gaming_workload_role_name" {
  description = "Name of the gaming workload role"
  value       = var.create_gaming_workload_role ? aws_iam_role.gaming_workload_role[0].name : null
}

output "gaming_application_policy_arn" {
  description = "ARN of the gaming application policy"
  value       = aws_iam_policy.gaming_application_policy.arn
}

# ==============================================================================
# CLOUDWATCH CONTAINER INSIGHTS OUTPUTS
# ==============================================================================

output "cloudwatch_container_insights_policy_arn" {
  description = "ARN of the CloudWatch Container Insights policy"
  value       = var.enable_container_insights ? aws_iam_policy.cloudwatch_container_insights_policy[0].arn : null
}

# ==============================================================================
# ROLE MAPPINGS FOR EKS ADDONS
# ==============================================================================

output "addon_role_mappings" {
  description = "Map of addon names to their IAM role ARNs for easy reference"
  value = {
    aws_load_balancer_controller = var.create_load_balancer_controller_role ? aws_iam_role.aws_load_balancer_controller_role[0].arn : null
    cluster_autoscaler          = var.create_cluster_autoscaler_role ? aws_iam_role.cluster_autoscaler_role[0].arn : null
    ebs_csi_driver             = var.create_ebs_csi_driver_role ? aws_iam_role.ebs_csi_driver_role[0].arn : null
    external_dns               = var.create_external_dns_role ? aws_iam_role.external_dns_role[0].arn : null
    gaming_workload            = var.create_gaming_workload_role ? aws_iam_role.gaming_workload_role[0].arn : null
  }
}

# ==============================================================================
# SERVICE ACCOUNT ANNOTATIONS
# ==============================================================================

output "service_account_annotations" {
  description = "Annotations for Kubernetes service accounts"
  value = {
    aws_load_balancer_controller = var.create_load_balancer_controller_role ? {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_load_balancer_controller_role[0].arn
    } : {}
    cluster_autoscaler = var.create_cluster_autoscaler_role ? {
      "eks.amazonaws.com/role-arn" = aws_iam_role.cluster_autoscaler_role[0].arn
    } : {}
    ebs_csi_driver = var.create_ebs_csi_driver_role ? {
      "eks.amazonaws.com/role-arn" = aws_iam_role.ebs_csi_driver_role[0].arn
    } : {}
    external_dns = var.create_external_dns_role ? {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns_role[0].arn
    } : {}
    gaming_workload = var.create_gaming_workload_role ? {
      "eks.amazonaws.com/role-arn" = aws_iam_role.gaming_workload_role[0].arn
    } : {}
  }
}

# ==============================================================================
# GAMING INFRASTRUCTURE SUMMARY
# ==============================================================================

output "gaming_infrastructure_summary" {
  description = "Summary of gaming infrastructure IAM configuration"
  value = {
    cluster_role_created           = true
    node_group_role_created       = true
    gaming_workload_role_created  = var.create_gaming_workload_role
    autoscaling_enabled           = var.create_cluster_autoscaler_role
    load_balancer_controller_enabled = var.create_load_balancer_controller_role
    persistent_storage_enabled    = var.create_ebs_csi_driver_role
    dns_management_enabled        = var.create_external_dns_role
    container_insights_enabled    = var.enable_container_insights
    gaming_features = {
      session_management = var.gaming_features.enable_session_management
      realtime_metrics  = var.gaming_features.enable_realtime_metrics
      auto_scaling      = var.gaming_features.enable_auto_scaling
      websocket_api     = var.gaming_features.enable_websocket_api
      leaderboards      = var.gaming_features.enable_leaderboards
    }
  }
}

# ==============================================================================
# SECURITY SUMMARY
# ==============================================================================

output "security_summary" {
  description = "Summary of security configurations"
  value = {
    max_session_duration = var.security_config.max_session_duration
    mfa_required        = var.security_config.require_mfa
    region_restricted   = var.environment_config.restrict_to_region
    environment_type    = var.environment
    roles_created       = length([
      aws_iam_role.eks_cluster_service_role.arn,
      aws_iam_role.eks_node_group_role.arn
    ]) + (var.create_load_balancer_controller_role ? 1 : 0) + 
    (var.create_cluster_autoscaler_role ? 1 : 0) + 
    (var.create_ebs_csi_driver_role ? 1 : 0) + 
    (var.create_external_dns_role ? 1 : 0) + 
    (var.create_gaming_workload_role ? 1 : 0)
  }
}
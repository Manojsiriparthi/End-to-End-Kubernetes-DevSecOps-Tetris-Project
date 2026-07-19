# ==============================================================================
# EKS CLUSTER MODULE - OUTPUTS
# ==============================================================================
# Description: Output values for EKS cluster module
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

# ==============================================================================
# CLUSTER BASIC OUTPUTS
# ==============================================================================

output "cluster_id" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_version" {
  description = "Kubernetes server version for the EKS cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_platform_version" {
  description = "Platform version for the EKS cluster"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = aws_eks_cluster.main.status
}

# ==============================================================================
# CLUSTER ENDPOINT OUTPUTS
# ==============================================================================

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

# ==============================================================================
# SECURITY OUTPUTS
# ==============================================================================

output "cluster_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_primary_security_group_id" {
  description = "Primary security group ID of the cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

# ==============================================================================
# IDENTITY AND ACCESS OUTPUTS
# ==============================================================================

output "cluster_identity_oidc_issuer" {
  description = "The URL of the identity provider for the cluster"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "cluster_identity_oidc_issuer_arn" {
  description = "The ARN of the OIDC identity provider for the cluster"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the cluster"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

# ==============================================================================
# CLOUDWATCH OUTPUTS
# ==============================================================================

output "cloudwatch_log_group_name" {
  description = "Name of cloudwatch log group for cluster logging"
  value       = aws_cloudwatch_log_group.cluster.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of cloudwatch log group for cluster logging"
  value       = aws_cloudwatch_log_group.cluster.arn
}

# ==============================================================================
# ADDON OUTPUTS
# ==============================================================================

output "cluster_addons" {
  description = "Map of attribute maps for all EKS cluster addons enabled"
  value = {
    vpc_cni = var.enable_vpc_cni_addon ? {
      arn           = aws_eks_addon.vpc_cni[0].arn
      status        = aws_eks_addon.vpc_cni[0].status
      addon_version = aws_eks_addon.vpc_cni[0].addon_version
    } : null
    coredns = var.enable_coredns_addon ? {
      arn           = aws_eks_addon.coredns[0].arn
      status        = aws_eks_addon.coredns[0].status
      addon_version = aws_eks_addon.coredns[0].addon_version
    } : null
    kube_proxy = var.enable_kube_proxy_addon ? {
      arn           = aws_eks_addon.kube_proxy[0].arn
      status        = aws_eks_addon.kube_proxy[0].status
      addon_version = aws_eks_addon.kube_proxy[0].addon_version
    } : null
    ebs_csi_driver = var.enable_ebs_csi_driver_addon ? {
      arn           = aws_eks_addon.ebs_csi_driver[0].arn
      status        = aws_eks_addon.ebs_csi_driver[0].status
      addon_version = aws_eks_addon.ebs_csi_driver[0].addon_version
    } : null
    efs_csi_driver = var.enable_efs_csi_driver_addon ? {
      arn           = aws_eks_addon.efs_csi_driver[0].arn
      status        = aws_eks_addon.efs_csi_driver[0].status
      addon_version = aws_eks_addon.efs_csi_driver[0].addon_version
    } : null
  }
}

# ==============================================================================
# FARGATE OUTPUTS
# ==============================================================================

output "fargate_profiles" {
  description = "Map of Fargate profiles"
  value = var.enable_fargate_profiles ? {
    gaming_workloads = {
      arn    = aws_eks_fargate_profile.gaming_workloads[0].arn
      status = aws_eks_fargate_profile.gaming_workloads[0].status
    }
  } : {}
}

# ==============================================================================
# KUBERNETES CONFIGURATION OUTPUTS
# ==============================================================================

output "cluster_tls_certificate_sha1_fingerprint" {
  description = "SHA1 fingerprint of the cluster TLS certificate"
  value       = data.tls_certificate.cluster_oidc_issuer_url.certificates[0].sha1_fingerprint
}

# ==============================================================================
# GAMING INFRASTRUCTURE OUTPUTS
# ==============================================================================

output "gaming_namespace" {
  description = "Gaming namespace information"
  value = var.create_gaming_namespace ? {
    name = kubernetes_namespace.gaming[0].metadata[0].name
    uid  = kubernetes_namespace.gaming[0].metadata[0].uid
  } : null
}

output "gaming_service_account" {
  description = "Gaming service account information"
  value = var.create_gaming_service_account ? {
    name      = kubernetes_service_account.gaming_workload[0].metadata[0].name
    namespace = kubernetes_service_account.gaming_workload[0].metadata[0].namespace
  } : null
}

output "cluster_autoscaler_service_account" {
  description = "Cluster autoscaler service account information"
  value = var.enable_cluster_autoscaler ? {
    name      = kubernetes_service_account.cluster_autoscaler[0].metadata[0].name
    namespace = kubernetes_service_account.cluster_autoscaler[0].metadata[0].namespace
  } : null
}

# ==============================================================================
# ACCESS ENTRY OUTPUTS
# ==============================================================================

output "platform_team_access_entries" {
  description = "Platform team access entry ARNs"
  value       = aws_eks_access_entry.platform_team[*].arn
}

output "gaming_dev_team_access_entries" {
  description = "Gaming development team access entry ARNs"
  value       = aws_eks_access_entry.gaming_dev_team[*].arn
}

# ==============================================================================
# KUBECTL CONFIGURATION
# ==============================================================================

output "kubeconfig_certificate_authority_data" {
  description = "Certificate authority data for kubectl configuration"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "kubectl_config" {
  description = "kubectl configuration for connecting to the cluster"
  value = {
    cluster_name                     = aws_eks_cluster.main.name
    endpoint                        = aws_eks_cluster.main.endpoint
    certificate_authority_data      = aws_eks_cluster.main.certificate_authority[0].data
    token_command                   = "aws eks get-token --cluster-name ${aws_eks_cluster.main.name}"
  }
}

# ==============================================================================
# GAMING INFRASTRUCTURE SUMMARY
# ==============================================================================

output "gaming_infrastructure_summary" {
  description = "Summary of gaming infrastructure configuration"
  value = {
    cluster = {
      name            = aws_eks_cluster.main.name
      version         = aws_eks_cluster.main.version
      endpoint        = aws_eks_cluster.main.endpoint
      status          = aws_eks_cluster.main.status
    }
    networking = {
      vpc_id                    = aws_eks_cluster.main.vpc_config[0].vpc_id
      subnet_ids               = aws_eks_cluster.main.vpc_config[0].subnet_ids
      cluster_security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
      endpoint_private_access   = aws_eks_cluster.main.vpc_config[0].endpoint_private_access
      endpoint_public_access    = aws_eks_cluster.main.vpc_config[0].endpoint_public_access
    }
    gaming_features = {
      gaming_namespace_created     = var.create_gaming_namespace
      gaming_service_account_created = var.create_gaming_service_account
      websocket_traffic_enabled    = var.enable_websocket_traffic
      container_insights_enabled   = var.enable_container_insights
      fargate_profiles_enabled     = var.enable_fargate_profiles
    }
    addons_enabled = {
      vpc_cni        = var.enable_vpc_cni_addon
      coredns        = var.enable_coredns_addon
      kube_proxy     = var.enable_kube_proxy_addon
      ebs_csi_driver = var.enable_ebs_csi_driver_addon
      efs_csi_driver = var.enable_efs_csi_driver_addon
    }
    optimizations = var.gaming_optimizations
    security = {
      encryption_enabled = var.kms_key_arn != ""
      gaming_traffic_rules_enabled = var.enable_gaming_traffic_rules
      access_entries_configured = length(var.platform_team_access) + length(var.gaming_dev_team_access) > 0
    }
  }
}

# ==============================================================================
# ENVIRONMENT CONFIGURATION
# ==============================================================================

output "environment_configuration" {
  description = "Environment-specific configuration summary"
  value = {
    environment = var.environment
    cluster_name = aws_eks_cluster.main.name
    log_retention_days = var.cloudwatch_log_group_retention_in_days
    gaming_logs_enabled = var.enable_gaming_logs
    environment_config = var.environment_config
  }
}

# ==============================================================================
# CONNECTION INFORMATION
# ==============================================================================

output "connection_info" {
  description = "Connection information for external tools"
  value = {
    aws_cli_command = "aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${aws_eks_cluster.main.name}"
    cluster_info = {
      name     = aws_eks_cluster.main.name
      endpoint = aws_eks_cluster.main.endpoint
      region   = data.aws_region.current.name
      version  = aws_eks_cluster.main.version
    }
  }
}
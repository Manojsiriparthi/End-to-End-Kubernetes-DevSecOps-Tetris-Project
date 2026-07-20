# ==============================================================================
# TEST ENVIRONMENT - OUTPUTS
# ==============================================================================
# Description: Output values for test environment
# Environment: Test (Production-like but smaller scale)
# Author: Platform Engineering Team
# Version: 2.0.0 - Fixed to match working dev structure
# ==============================================================================

# ==============================================================================
# VPC AND NETWORKING OUTPUTS
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

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.networking.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = module.networking.nat_gateway_ids
}

# ==============================================================================
# EKS CLUSTER OUTPUTS
# ==============================================================================

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks_cluster.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks_cluster.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks_cluster.cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks_cluster.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = module.eks_cluster.cluster_version
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = module.eks_cluster.cluster_status
}

# ==============================================================================
# OIDC PROVIDER OUTPUTS
# ==============================================================================

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks_cluster.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for the EKS cluster"
  value       = module.eks_cluster.oidc_provider_arn
}

# ==============================================================================
# NODE GROUP OUTPUTS
# ==============================================================================

output "node_groups" {
  description = "Map of node group configurations and their status"
  value = {
    for k, v in module.node_groups.node_groups : k => {
      node_group_arn        = v.node_group_arn
      node_group_status     = v.node_group_status
      capacity_type         = v.capacity_type
      instance_types        = v.instance_types
      ami_type             = v.ami_type
      node_group_resources = v.node_group_resources
    }
  }
  sensitive = true
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS node groups"
  value       = module.eks_cluster.node_security_group_id
}

# ==============================================================================
# BASIC IAM OUTPUTS (LAYER 1)
# ==============================================================================

output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster service role"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "eks_node_group_role_arn" {
  description = "ARN of the EKS node group role"
  value       = aws_iam_role.eks_node_group_role.arn
}

# ==============================================================================
# IRSA IAM OUTPUTS (LAYER 3)
# ==============================================================================

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM role"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

# ==============================================================================
# SECURITY GROUP OUTPUTS
# ==============================================================================

output "bastion_security_group_id" {
  description = "Security group ID for bastion host"
  value       = module.security_groups.bastion_sg_id
}

output "eks_cluster_additional_security_group_id" {
  description = "Additional security group ID for EKS cluster"
  value       = module.security_groups.eks_cluster_additional_sg_id
}

output "eks_nodes_security_group_id" {
  description = "Security group ID for EKS nodes"
  value       = module.security_groups.eks_nodes_sg_id
}

output "alb_security_group_id" {
  description = "Security group ID for Application Load Balancer"
  value       = module.security_groups.alb_sg_id
}

output "database_security_group_id" {
  description = "Security group ID for database"
  value       = module.security_groups.database_sg_id
}

# ==============================================================================
# KMS OUTPUTS
# ==============================================================================

output "kms_cluster_key_arn" {
  description = "ARN of the KMS key used for EKS cluster encryption"
  value       = module.kms.cluster_kms_key_arn
}

output "kms_cluster_key_id" {
  description = "ID of the KMS key used for EKS cluster encryption"
  value       = module.kms.cluster_kms_key_id
}

# ==============================================================================
# KUBECTL CONNECTION COMMAND
# ==============================================================================

output "kubectl_config_command" {
  description = "Command to configure kubectl for the EKS cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks_cluster.cluster_name}"
}

# ==============================================================================
# DEPLOYMENT LAYERS SUMMARY
# ==============================================================================

output "deployment_layers_summary" {
  description = "Summary of infrastructure deployment layers"
  value = {
    layer_1_basic = {
      description = "Networking, KMS, Security Groups, Basic IAM Roles"
      components = [
        "VPC and Subnets",
        "KMS Keys", 
        "Security Groups",
        "EKS Cluster Service Role",
        "EKS Node Group Role"
      ]
      status = "completed"
    }
    layer_2_compute = {
      description = "EKS Cluster and Node Groups"
      components = [
        "EKS Cluster",
        "EKS Node Groups",
        "OIDC Provider"
      ]
      status = "completed"
    }
    layer_3_advanced_iam = {
      description = "IRSA Roles (Post-EKS)"
      components = [
        "AWS Load Balancer Controller Role",
        "Future IRSA Roles"
      ]
      status = "completed"
    }
  }
}

# ==============================================================================
# TEST ENVIRONMENT INFORMATION
# ==============================================================================

output "environment_info" {
  description = "Information about the deployed test environment"
  value = {
    project_name           = var.project_name
    environment           = "test"
    aws_region            = var.aws_region
    cluster_name          = module.eks_cluster.cluster_name
    vpc_cidr              = var.vpc_cidr
    node_groups           = keys(var.node_group_configs)
    deployment_date       = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
    architecture          = "layered-deployment"
    production_like_testing = true
    multi_az_deployment   = true
    circular_dependency_resolved = true
  }
}

# ==============================================================================
# TEST-SPECIFIC SUMMARY
# ==============================================================================

output "test_environment_summary" {
  description = "Summary of test environment configuration"
  value = {
    environment_type      = "Production-like Testing"
    nat_gateways         = "Multi-AZ (HA)"
    encryption           = "Enabled"
    monitoring           = "Enhanced"
    node_count           = sum([for ng in var.node_group_configs : ng.desired_capacity])
    ami_type             = "AL2023_x86_64_STANDARD"
    testing_capabilities = [
      "Production-like scale testing",
      "Multi-AZ failover testing", 
      "Load balancer testing",
      "Autoscaling testing",
      "Security testing"
    ]
  }
}
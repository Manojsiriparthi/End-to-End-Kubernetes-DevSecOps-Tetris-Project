# ==============================================================================
# DEV ENVIRONMENT - OUTPUTS
# ==============================================================================
# Description: Output values for development environment
# Environment: Development
# Author: Platform Engineering Team
# Version: 1.0.0
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

output "public_route_table_ids" {
  description = "IDs of the public route tables"
  value       = module.networking.public_route_table_ids
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = module.networking.private_route_table_ids
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

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = module.eks_cluster.cluster_iam_role_arn
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

output "cluster_platform_version" {
  description = "Platform version for the EKS cluster"
  value       = module.eks_cluster.cluster_platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = module.eks_cluster.cluster_status
}

output "cluster_primary_security_group_id" {
  description = "The cluster primary security group ID created by EKS"
  value       = module.eks_cluster.cluster_primary_security_group_id
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
# IAM OUTPUTS
# ==============================================================================

output "cluster_service_role_arn" {
  description = "ARN of the EKS cluster service role"
  value       = module.iam.eks_cluster_role_arn
}

output "node_group_role_arn" {
  description = "ARN of the EKS node group role"
  value       = module.iam.eks_node_group_role_arn
}

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM role"
  value       = module.iam.aws_load_balancer_controller_role_arn
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of the Cluster Autoscaler IAM role"
  value       = module.iam.cluster_autoscaler_role_arn
}

output "ebs_csi_driver_role_arn" {
  description = "ARN of the EBS CSI Driver IAM role"
  value       = module.iam.ebs_csi_driver_role_arn
}

output "karpenter_role_arn" {
  description = "ARN of the Karpenter IAM role"
  value       = module.iam.karpenter_role_arn
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
# ENVIRONMENT INFORMATION
# ==============================================================================

output "environment_info" {
  description = "Information about the deployed environment"
  value = {
    project_name    = var.project_name
    environment     = "dev"
    aws_region      = var.aws_region
    cluster_name    = module.eks_cluster.cluster_name
    vpc_cidr        = var.vpc_cidr
    node_groups     = keys(var.node_group_configs)
    deployment_date = formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())
  }
}

# ==============================================================================
# COST OPTIMIZATION NOTES FOR DEV
# ==============================================================================

output "cost_optimization_notes" {
  description = "Cost optimization features enabled for dev environment"
  value = {
    single_nat_gateway      = "Enabled - Cost optimization for dev"
    spot_instances          = "Used where possible for cost savings"
    reduced_monitoring      = "CloudWatch monitoring disabled for cost"
    minimal_logging         = "Only essential EKS logs enabled"
    no_vpn_gateway         = "VPN gateway disabled for cost optimization"
    basic_encryption       = "Basic KMS encryption only"
    estimated_monthly_cost = "~$200-400 USD (varies by usage)"
  }
}
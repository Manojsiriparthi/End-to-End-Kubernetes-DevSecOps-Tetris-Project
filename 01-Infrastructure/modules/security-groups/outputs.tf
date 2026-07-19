# ==============================================================================
# SECURITY GROUPS MODULE - OUTPUTS
# ==============================================================================
# Description: Output values for security groups module
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

# ==============================================================================
# EKS CLUSTER SECURITY GROUP OUTPUTS
# ==============================================================================

output "eks_cluster_security_group_id" {
  description = "ID of the EKS cluster security group"
  value       = aws_security_group.eks_cluster.id
}

output "eks_cluster_security_group_arn" {
  description = "ARN of the EKS cluster security group"
  value       = aws_security_group.eks_cluster.arn
}

output "eks_cluster_security_group_name" {
  description = "Name of the EKS cluster security group"
  value       = aws_security_group.eks_cluster.name
}

# ==============================================================================
# EKS NODES SECURITY GROUP OUTPUTS
# ==============================================================================

output "eks_nodes_security_group_id" {
  description = "ID of the EKS nodes security group"
  value       = aws_security_group.eks_nodes.id
}

output "eks_nodes_security_group_arn" {
  description = "ARN of the EKS nodes security group"
  value       = aws_security_group.eks_nodes.arn
}

output "eks_nodes_security_group_name" {
  description = "Name of the EKS nodes security group"
  value       = aws_security_group.eks_nodes.name
}

# ==============================================================================
# GAMING APPLICATION SECURITY GROUP OUTPUTS
# ==============================================================================

output "gaming_app_security_group_id" {
  description = "ID of the gaming application security group"
  value       = aws_security_group.gaming_app.id
}

output "gaming_app_security_group_arn" {
  description = "ARN of the gaming application security group"
  value       = aws_security_group.gaming_app.arn
}

output "gaming_app_security_group_name" {
  description = "Name of the gaming application security group"
  value       = aws_security_group.gaming_app.name
}

# ==============================================================================
# LOAD BALANCER SECURITY GROUP OUTPUTS
# ==============================================================================

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "alb_security_group_arn" {
  description = "ARN of the ALB security group"
  value       = aws_security_group.alb.arn
}

output "alb_security_group_name" {
  description = "Name of the ALB security group"
  value       = aws_security_group.alb.name
}

# ==============================================================================
# DATABASE SECURITY GROUP OUTPUTS
# ==============================================================================

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = var.create_database_security_group ? aws_security_group.database[0].id : null
}

output "database_security_group_arn" {
  description = "ARN of the database security group"
  value       = var.create_database_security_group ? aws_security_group.database[0].arn : null
}

output "database_security_group_name" {
  description = "Name of the database security group"
  value       = var.create_database_security_group ? aws_security_group.database[0].name : null
}

# ==============================================================================
# REDIS SECURITY GROUP OUTPUTS
# ==============================================================================

output "redis_security_group_id" {
  description = "ID of the Redis security group"
  value       = var.create_redis_security_group ? aws_security_group.redis[0].id : null
}

output "redis_security_group_arn" {
  description = "ARN of the Redis security group"
  value       = var.create_redis_security_group ? aws_security_group.redis[0].arn : null
}

output "redis_security_group_name" {
  description = "Name of the Redis security group"
  value       = var.create_redis_security_group ? aws_security_group.redis[0].name : null
}

# ==============================================================================
# MONITORING SECURITY GROUP OUTPUTS
# ==============================================================================

output "monitoring_security_group_id" {
  description = "ID of the monitoring security group"
  value       = var.create_monitoring_security_group ? aws_security_group.monitoring[0].id : null
}

output "monitoring_security_group_arn" {
  description = "ARN of the monitoring security group"
  value       = var.create_monitoring_security_group ? aws_security_group.monitoring[0].arn : null
}

output "monitoring_security_group_name" {
  description = "Name of the monitoring security group"
  value       = var.create_monitoring_security_group ? aws_security_group.monitoring[0].name : null
}

# ==============================================================================
# BASTION SECURITY GROUP OUTPUTS
# ==============================================================================

output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = var.create_bastion_security_group ? aws_security_group.bastion[0].id : null
}

output "bastion_security_group_arn" {
  description = "ARN of the bastion security group"
  value       = var.create_bastion_security_group ? aws_security_group.bastion[0].arn : null
}

output "bastion_security_group_name" {
  description = "Name of the bastion security group"
  value       = var.create_bastion_security_group ? aws_security_group.bastion[0].name : null
}

# ==============================================================================
# SECURITY GROUP MAPPINGS
# ==============================================================================

output "security_group_mappings" {
  description = "Map of security group names to IDs for easy reference"
  value = {
    eks_cluster     = aws_security_group.eks_cluster.id
    eks_nodes      = aws_security_group.eks_nodes.id
    gaming_app     = aws_security_group.gaming_app.id
    alb           = aws_security_group.alb.id
    database      = var.create_database_security_group ? aws_security_group.database[0].id : null
    redis         = var.create_redis_security_group ? aws_security_group.redis[0].id : null
    monitoring    = var.create_monitoring_security_group ? aws_security_group.monitoring[0].id : null
    bastion       = var.create_bastion_security_group ? aws_security_group.bastion[0].id : null
  }
}

output "security_group_arns" {
  description = "Map of security group names to ARNs"
  value = {
    eks_cluster     = aws_security_group.eks_cluster.arn
    eks_nodes      = aws_security_group.eks_nodes.arn
    gaming_app     = aws_security_group.gaming_app.arn
    alb           = aws_security_group.alb.arn
    database      = var.create_database_security_group ? aws_security_group.database[0].arn : null
    redis         = var.create_redis_security_group ? aws_security_group.redis[0].arn : null
    monitoring    = var.create_monitoring_security_group ? aws_security_group.monitoring[0].arn : null
    bastion       = var.create_bastion_security_group ? aws_security_group.bastion[0].arn : null
  }
}

# ==============================================================================
# GAMING INFRASTRUCTURE OUTPUTS
# ==============================================================================

output "gaming_infrastructure_summary" {
  description = "Summary of gaming infrastructure security configuration"
  value = {
    gaming_traffic_enabled     = var.enable_gaming_traffic
    websocket_traffic_enabled  = var.enable_websocket_traffic
    public_access_enabled      = var.enable_public_access
    metrics_collection_enabled = var.enable_gaming_metrics
    security_groups_created = {
      cluster     = true
      nodes      = true
      gaming_app = true
      alb        = true
      database   = var.create_database_security_group
      redis      = var.create_redis_security_group
      monitoring = var.create_monitoring_security_group
      bastion    = var.create_bastion_security_group
    }
    gaming_ports = var.gaming_ports
    environment_config = var.environment_config
  }
}

# ==============================================================================
# SECURITY COMPLIANCE OUTPUTS
# ==============================================================================

output "security_compliance_summary" {
  description = "Security compliance and configuration summary"
  value = {
    environment = var.environment
    vpc_id     = var.vpc_id
    compliance_settings = var.security_compliance
    access_control = {
      authorized_networks    = length(var.authorized_networks)
      allowed_cidrs         = length(var.allowed_cidrs)
      office_networks       = length(var.office_network_cidrs)
      public_access_enabled = var.enable_public_access
    }
    security_features = {
      ssl_required              = var.security_compliance.require_ssl
      security_groups_logging   = var.security_compliance.enable_security_groups_logging
      default_sg_restricted     = var.security_compliance.restrict_default_sg
      nacls_enabled            = var.security_compliance.enable_nacls
    }
  }
}

# ==============================================================================
# NETWORKING OUTPUTS
# ==============================================================================

output "networking_summary" {
  description = "Networking configuration summary"
  value = {
    vpc_cidr_block       = var.vpc_cidr_block
    private_subnet_cidrs = var.private_subnet_cidrs
    public_subnet_cidrs  = var.public_subnet_cidrs
    cross_az_traffic     = var.regional_config.enable_cross_az_traffic
    multi_region_access  = var.regional_config.enable_multi_region_access
  }
}

# ==============================================================================
# OPERATIONAL OUTPUTS
# ==============================================================================

output "operational_info" {
  description = "Operational information for gaming infrastructure"
  value = {
    gaming_optimizations = var.gaming_optimizations
    load_balancer_config = var.load_balancer_config
    custom_rules_count = {
      ingress = length(var.custom_ingress_rules)
      egress  = length(var.custom_egress_rules)
    }
    database_config = {
      postgresql_enabled = var.enable_postgresql
      redis_cluster_enabled = var.enable_redis_cluster
    }
  }
}
# ==============================================================================
# NODE GROUPS MODULE - OUTPUTS
# ==============================================================================
# Description: Output values for node groups module
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

# ==============================================================================
# LAUNCH TEMPLATE OUTPUTS
# ==============================================================================

output "launch_template_id" {
  description = "ID of the launch template for gaming nodes"
  value       = aws_launch_template.gaming_nodes.id
}

output "launch_template_arn" {
  description = "ARN of the launch template for gaming nodes"
  value       = aws_launch_template.gaming_nodes.arn
}

output "launch_template_latest_version" {
  description = "Latest version of the launch template"
  value       = aws_launch_template.gaming_nodes.latest_version
}

# ==============================================================================
# PRIMARY NODE GROUP OUTPUTS
# ==============================================================================

output "gaming_primary_node_group_arn" {
  description = "ARN of the primary gaming node group"
  value       = aws_eks_node_group.gaming_primary.arn
}

output "gaming_primary_node_group_status" {
  description = "Status of the primary gaming node group"
  value       = aws_eks_node_group.gaming_primary.status
}

output "gaming_primary_node_group_capacity_type" {
  description = "Capacity type of the primary gaming node group"
  value       = aws_eks_node_group.gaming_primary.capacity_type
}

output "gaming_primary_node_group_instance_types" {
  description = "Instance types of the primary gaming node group"
  value       = aws_eks_node_group.gaming_primary.instance_types
}

output "gaming_primary_node_group_scaling_config" {
  description = "Scaling configuration of the primary gaming node group"
  value       = aws_eks_node_group.gaming_primary.scaling_config
}

# ==============================================================================
# SPOT NODE GROUP OUTPUTS
# ==============================================================================

output "gaming_spot_node_group_arn" {
  description = "ARN of the spot gaming node group"
  value       = var.enable_spot_node_group ? aws_eks_node_group.gaming_spot[0].arn : null
}

output "gaming_spot_node_group_status" {
  description = "Status of the spot gaming node group"
  value       = var.enable_spot_node_group ? aws_eks_node_group.gaming_spot[0].status : null
}

output "gaming_spot_node_group_capacity_type" {
  description = "Capacity type of the spot gaming node group"
  value       = var.enable_spot_node_group ? aws_eks_node_group.gaming_spot[0].capacity_type : null
}

output "gaming_spot_node_group_instance_types" {
  description = "Instance types of the spot gaming node group"
  value       = var.enable_spot_node_group ? aws_eks_node_group.gaming_spot[0].instance_types : null
}

# ==============================================================================
# GPU NODE GROUP OUTPUTS
# ==============================================================================

output "gaming_gpu_node_group_arn" {
  description = "ARN of the GPU gaming node group"
  value       = var.enable_gpu_node_group ? aws_eks_node_group.gaming_gpu[0].arn : null
}

output "gaming_gpu_node_group_status" {
  description = "Status of the GPU gaming node group"
  value       = var.enable_gpu_node_group ? aws_eks_node_group.gaming_gpu[0].status : null
}

output "gaming_gpu_node_group_capacity_type" {
  description = "Capacity type of the GPU gaming node group"
  value       = var.enable_gpu_node_group ? aws_eks_node_group.gaming_gpu[0].capacity_type : null
}

output "gaming_gpu_node_group_instance_types" {
  description = "Instance types of the GPU gaming node group"
  value       = var.enable_gpu_node_group ? aws_eks_node_group.gaming_gpu[0].instance_types : null
}

# ==============================================================================
# ARM NODE GROUP OUTPUTS
# ==============================================================================

output "gaming_arm_node_group_arn" {
  description = "ARN of the ARM gaming node group"
  value       = var.enable_arm_node_group ? aws_eks_node_group.gaming_arm[0].arn : null
}

output "gaming_arm_node_group_status" {
  description = "Status of the ARM gaming node group"
  value       = var.enable_arm_node_group ? aws_eks_node_group.gaming_arm[0].status : null
}

output "gaming_arm_node_group_capacity_type" {
  description = "Capacity type of the ARM gaming node group"
  value       = var.enable_arm_node_group ? aws_eks_node_group.gaming_arm[0].capacity_type : null
}

output "gaming_arm_node_group_instance_types" {
  description = "Instance types of the ARM gaming node group"
  value       = var.enable_arm_node_group ? aws_eks_node_group.gaming_arm[0].instance_types : null
}

# ==============================================================================
# NODE GROUP SUMMARY
# ==============================================================================

output "node_groups_summary" {
  description = "Summary of all created node groups"
  value = {
    primary = {
      arn           = aws_eks_node_group.gaming_primary.arn
      status        = aws_eks_node_group.gaming_primary.status
      capacity_type = aws_eks_node_group.gaming_primary.capacity_type
      instance_types = aws_eks_node_group.gaming_primary.instance_types
      scaling_config = aws_eks_node_group.gaming_primary.scaling_config
    }
    spot = var.enable_spot_node_group ? {
      arn           = aws_eks_node_group.gaming_spot[0].arn
      status        = aws_eks_node_group.gaming_spot[0].status
      capacity_type = aws_eks_node_group.gaming_spot[0].capacity_type
      instance_types = aws_eks_node_group.gaming_spot[0].instance_types
      scaling_config = aws_eks_node_group.gaming_spot[0].scaling_config
    } : null
    gpu = var.enable_gpu_node_group ? {
      arn           = aws_eks_node_group.gaming_gpu[0].arn
      status        = aws_eks_node_group.gaming_gpu[0].status
      capacity_type = aws_eks_node_group.gaming_gpu[0].capacity_type
      instance_types = aws_eks_node_group.gaming_gpu[0].instance_types
      scaling_config = aws_eks_node_group.gaming_gpu[0].scaling_config
    } : null
    arm = var.enable_arm_node_group ? {
      arn           = aws_eks_node_group.gaming_arm[0].arn
      status        = aws_eks_node_group.gaming_arm[0].status
      capacity_type = aws_eks_node_group.gaming_arm[0].capacity_type
      instance_types = aws_eks_node_group.gaming_arm[0].instance_types
      scaling_config = aws_eks_node_group.gaming_arm[0].scaling_config
    } : null
  }
}

# ==============================================================================
# GAMING INFRASTRUCTURE OUTPUTS
# ==============================================================================

output "gaming_infrastructure_summary" {
  description = "Summary of gaming infrastructure configuration"
  value = {
    cluster_name = var.cluster_name
    environment = var.environment
    node_groups_created = {
      primary = true
      spot    = var.enable_spot_node_group
      gpu     = var.enable_gpu_node_group
      arm     = var.enable_arm_node_group
    }
    gaming_optimizations = {
      enabled              = var.enable_gaming_optimizations
      low_latency         = var.gaming_optimizations.enable_low_latency
      enhanced_networking = var.gaming_optimizations.enable_enhanced_networking
      cpu_optimizations   = var.gaming_optimizations.enable_cpu_optimizations
      memory_optimization = var.gaming_optimizations.enable_memory_optimization
      disk_optimization   = var.gaming_optimizations.enable_disk_optimization
    }
    storage_configuration = {
      disk_type      = var.disk_type
      disk_size      = var.disk_size
      encryption_enabled = var.enable_ebs_encryption
      iops          = var.disk_type == "gp3" ? var.disk_iops : null
      throughput    = var.disk_type == "gp3" ? var.disk_throughput : null
    }
    monitoring = {
      detailed_monitoring_enabled = var.enable_detailed_monitoring
      container_insights_enabled = var.enable_container_insights
    }
  }
}

# ==============================================================================
# CAPACITY OUTPUTS
# ==============================================================================

output "total_capacity_summary" {
  description = "Total capacity across all node groups"
  value = {
    primary_capacity = {
      min     = aws_eks_node_group.gaming_primary.scaling_config[0].min_size
      max     = aws_eks_node_group.gaming_primary.scaling_config[0].max_size
      desired = aws_eks_node_group.gaming_primary.scaling_config[0].desired_size
    }
    spot_capacity = var.enable_spot_node_group ? {
      min     = aws_eks_node_group.gaming_spot[0].scaling_config[0].min_size
      max     = aws_eks_node_group.gaming_spot[0].scaling_config[0].max_size
      desired = aws_eks_node_group.gaming_spot[0].scaling_config[0].desired_size
    } : null
    gpu_capacity = var.enable_gpu_node_group ? {
      min     = aws_eks_node_group.gaming_gpu[0].scaling_config[0].min_size
      max     = aws_eks_node_group.gaming_gpu[0].scaling_config[0].max_size
      desired = aws_eks_node_group.gaming_gpu[0].scaling_config[0].desired_size
    } : null
    arm_capacity = var.enable_arm_node_group ? {
      min     = aws_eks_node_group.gaming_arm[0].scaling_config[0].min_size
      max     = aws_eks_node_group.gaming_arm[0].scaling_config[0].max_size
      desired = aws_eks_node_group.gaming_arm[0].scaling_config[0].desired_size
    } : null
    total_min_nodes = aws_eks_node_group.gaming_primary.scaling_config[0].min_size + 
                     (var.enable_spot_node_group ? aws_eks_node_group.gaming_spot[0].scaling_config[0].min_size : 0) +
                     (var.enable_gpu_node_group ? aws_eks_node_group.gaming_gpu[0].scaling_config[0].min_size : 0) +
                     (var.enable_arm_node_group ? aws_eks_node_group.gaming_arm[0].scaling_config[0].min_size : 0)
    total_max_nodes = aws_eks_node_group.gaming_primary.scaling_config[0].max_size + 
                     (var.enable_spot_node_group ? aws_eks_node_group.gaming_spot[0].scaling_config[0].max_size : 0) +
                     (var.enable_gpu_node_group ? aws_eks_node_group.gaming_gpu[0].scaling_config[0].max_size : 0) +
                     (var.enable_arm_node_group ? aws_eks_node_group.gaming_arm[0].scaling_config[0].max_size : 0)
  }
}

# ==============================================================================
# SECURITY OUTPUTS
# ==============================================================================

output "security_configuration" {
  description = "Security configuration for node groups"
  value = {
    remote_access_enabled = var.enable_remote_access
    key_pair_name        = var.key_pair_name
    security_group_ids   = var.security_group_ids
    ebs_encryption_enabled = var.enable_ebs_encryption
    kms_key_id          = var.ebs_kms_key_id
  }
}

# ==============================================================================
# OPERATIONAL OUTPUTS
# ==============================================================================

output "operational_info" {
  description = "Operational information for node groups"
  value = {
    ami_id_used                = var.ami_id != "" ? var.ami_id : data.aws_ssm_parameter.eks_ami.value
    kubernetes_version         = var.node_group_version
    max_unavailable_percentage = var.max_unavailable_percentage
    subnet_ids                = var.subnet_ids
    launch_template_version    = aws_launch_template.gaming_nodes.latest_version
  }
}
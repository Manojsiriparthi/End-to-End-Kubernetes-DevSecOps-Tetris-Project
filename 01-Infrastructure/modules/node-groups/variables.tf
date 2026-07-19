# ==============================================================================
# NODE GROUPS MODULE - VARIABLES
# ==============================================================================
# Description: Variable definitions for node groups module
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

# ==============================================================================
# CORE VARIABLES
# ==============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, prod."
  }
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# EKS CLUSTER CONFIGURATION
# ==============================================================================

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
  default     = ""
}

variable "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  type        = string
  default     = ""
}

variable "node_role_arn" {
  description = "ARN of the IAM role that provides permissions for the node group"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the node group"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the node group"
  type        = list(string)
  default     = []
}

# ==============================================================================
# NODE GROUP CONFIGURATION
# ==============================================================================

variable "node_group_version" {
  description = "Kubernetes version for the node group"
  type        = string
  default     = null
}

variable "ami_id" {
  description = "AMI ID for the node group (leave empty to use EKS optimized AMI)"
  type        = string
  default     = ""
}

variable "disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 50
}

variable "disk_type" {
  description = "EBS volume type for worker nodes"
  type        = string
  default     = "gp3"
  
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.disk_type)
    error_message = "Disk type must be one of: gp2, gp3, io1, io2."
  }
}

variable "disk_iops" {
  description = "IOPS for gp3 or io1/io2 volumes"
  type        = number
  default     = 3000
}

variable "disk_throughput" {
  description = "Throughput for gp3 volumes (MB/s)"
  type        = number
  default     = 125
}

variable "enable_ebs_encryption" {
  description = "Enable EBS encryption for node group volumes"
  type        = bool
  default     = true
}

variable "ebs_kms_key_id" {
  description = "KMS key ID for EBS encryption"
  type        = string
  default     = ""
}

# ==============================================================================
# SCALING CONFIGURATION
# ==============================================================================

variable "max_unavailable_percentage" {
  description = "Maximum percentage of nodes unavailable during update"
  type        = number
  default     = 25
  
  validation {
    condition     = var.max_unavailable_percentage >= 1 && var.max_unavailable_percentage <= 100
    error_message = "Max unavailable percentage must be between 1 and 100."
  }
}

# ==============================================================================
# SPOT INSTANCES CONFIGURATION
# ==============================================================================

variable "use_spot_instances" {
  description = "Use spot instances for primary node group"
  type        = bool
  default     = false
}

variable "enable_spot_node_group" {
  description = "Enable dedicated spot instances node group"
  type        = bool
  default     = false
}

variable "spot_instance_types" {
  description = "Instance types for spot node group"
  type        = list(string)
  default     = ["t3.medium", "t3.large", "m5.large"]
}

variable "spot_desired_size" {
  description = "Desired number of spot instances"
  type        = number
  default     = 2
}

variable "spot_max_size" {
  description = "Maximum number of spot instances"
  type        = number
  default     = 10
}

variable "spot_min_size" {
  description = "Minimum number of spot instances"
  type        = number
  default     = 0
}

# ==============================================================================
# GPU NODE GROUP CONFIGURATION
# ==============================================================================

variable "enable_gpu_node_group" {
  description = "Enable GPU node group for advanced gaming features"
  type        = bool
  default     = false
}

variable "gpu_instance_types" {
  description = "GPU instance types for gaming workloads"
  type        = list(string)
  default     = ["g4dn.xlarge", "g4dn.2xlarge"]
}

variable "gpu_desired_size" {
  description = "Desired number of GPU instances"
  type        = number
  default     = 1
}

variable "gpu_max_size" {
  description = "Maximum number of GPU instances"
  type        = number
  default     = 3
}

variable "gpu_min_size" {
  description = "Minimum number of GPU instances"
  type        = number
  default     = 0
}

variable "gpu_disk_size" {
  description = "Disk size for GPU nodes (larger for ML/AI workloads)"
  type        = number
  default     = 100
}

# ==============================================================================
# ARM NODE GROUP CONFIGURATION
# ==============================================================================

variable "enable_arm_node_group" {
  description = "Enable ARM-based node group for cost optimization"
  type        = bool
  default     = false
}

variable "arm_instance_types" {
  description = "ARM instance types for cost-optimized gaming workloads"
  type        = list(string)
  default     = ["m6g.medium", "m6g.large", "c6g.large"]
}

variable "arm_desired_size" {
  description = "Desired number of ARM instances"
  type        = number
  default     = 2
}

variable "arm_max_size" {
  description = "Maximum number of ARM instances"
  type        = number
  default     = 5
}

variable "arm_min_size" {
  description = "Minimum number of ARM instances"
  type        = number
  default     = 0
}

# ==============================================================================
# GAMING OPTIMIZATIONS
# ==============================================================================

variable "enable_gaming_optimizations" {
  description = "Enable gaming-specific optimizations in user data"
  type        = bool
  default     = true
}

variable "gaming_optimizations" {
  description = "Gaming-specific optimizations configuration"
  type = object({
    enable_low_latency        = optional(bool, true)
    enable_enhanced_networking = optional(bool, true)
    enable_cpu_optimizations  = optional(bool, true)
    enable_memory_optimization = optional(bool, true)
    enable_disk_optimization  = optional(bool, true)
  })
  default = {
    enable_low_latency        = true
    enable_enhanced_networking = true
    enable_cpu_optimizations  = true
    enable_memory_optimization = true
    enable_disk_optimization  = true
  }
}

# ==============================================================================
# NODE LABELS AND TAINTS
# ==============================================================================

variable "node_labels" {
  description = "Labels to apply to all nodes"
  type        = map(string)
  default     = {}
}

variable "gaming_taints" {
  description = "Taints to apply to gaming nodes"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

# ==============================================================================
# REMOTE ACCESS CONFIGURATION
# ==============================================================================

variable "enable_remote_access" {
  description = "Enable remote access to worker nodes"
  type        = bool
  default     = false
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for SSH access to nodes"
  type        = string
  default     = ""
}

variable "remote_access_security_group_ids" {
  description = "Security group IDs for remote access"
  type        = list(string)
  default     = []
}

# ==============================================================================
# MONITORING CONFIGURATION
# ==============================================================================

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for instances"
  type        = bool
  default     = true
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

# ==============================================================================
# ENVIRONMENT-SPECIFIC OVERRIDES
# ==============================================================================

variable "environment_overrides" {
  description = "Environment-specific configuration overrides"
  type = object({
    primary_instance_types = optional(list(string), [])
    primary_desired_size   = optional(number, null)
    primary_min_size      = optional(number, null)
    primary_max_size      = optional(number, null)
    enable_spot_by_default = optional(bool, null)
  })
  default = {
    primary_instance_types = []
    primary_desired_size   = null
    primary_min_size      = null
    primary_max_size      = null
    enable_spot_by_default = null
  }
}
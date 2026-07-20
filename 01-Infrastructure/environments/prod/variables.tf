# ==============================================================================
# PROD ENVIRONMENT - VARIABLES
# ==============================================================================
# Description: Variable definitions for production environment
# Environment: Production (Maximum availability, security, performance, disaster recovery)
# Author: Platform Engineering Team
# Version: 2.0.0
# ==============================================================================

# ==============================================================================
# CORE CONFIGURATION VARIABLES
# ==============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "tetris-platform"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"  # Production in us-east-1 for lower latency
  
  validation {
    condition = contains([
      "us-east-1", "us-east-2", "us-west-1", "us-west-2",
      "eu-west-1", "eu-west-2", "eu-west-3", "eu-central-1",
      "ap-southeast-1", "ap-southeast-2", "ap-northeast-1", "ap-northeast-2"
    ], var.aws_region)
    error_message = "AWS region must be a valid region."
  }
}

variable "owner" {
  description = "Owner of the infrastructure"
  type        = string
  default     = "platform-engineering-team"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "engineering-production"
}

variable "business_unit" {
  description = "Business unit responsible for the infrastructure"
  type        = string
  default     = "platform"
}

# ==============================================================================
# NETWORKING VARIABLES
# ==============================================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.100.0.0/16"  # Production environment VPC
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "authorized_networks" {
  description = "List of authorized CIDR blocks for cluster API access (RESTRICTED)"
  type        = list(string)
  default     = []  # Must be explicitly set for production
  
  validation {
    condition     = length(var.authorized_networks) > 0
    error_message = "Authorized networks must be explicitly configured for production."
  }
}

variable "allowed_cidrs" {
  description = "List of CIDR blocks allowed to access load balancer (RESTRICTED)"
  type        = list(string)
  default     = []  # Must be explicitly set for production
}

variable "office_network_cidrs" {
  description = "List of office network CIDR blocks for administrative access"
  type        = list(string)
  default     = []  # Must be explicitly set for production
}

variable "gaming_traffic_cidrs" {
  description = "CIDR blocks allowed for gaming traffic"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

# ==============================================================================
# EKS CLUSTER VARIABLES
# ==============================================================================

variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.33"
  
  validation {
    condition = contains([
      "1.33", "1.34", "1.35"  # Use stable versions for production
    ], var.eks_cluster_version)
    error_message = "EKS cluster version must be a production-supported version."
  }
}

# ==============================================================================
# NODE GROUP CONFIGURATIONS
# ==============================================================================

variable "node_group_configs" {
  description = "Configuration for EKS node groups"
  type = map(object({
    node_group_name = string
    subnet_type     = string  # "public", "private", or "database"
    
    # Instance Configuration
    instance_types = list(string)
    ami_type      = string
    capacity_type = string  # "ON_DEMAND" or "SPOT"
    
    # Scaling Configuration
    min_size         = number
    max_size         = number
    desired_capacity = number
    
    # Node Configuration
    disk_size    = number
    disk_type    = string
    disk_encrypted = bool
    
    # Networking
    remote_access = object({
      ec2_ssh_key               = string
      source_security_group_ids = list(string)
    })
    
    # Taints and Labels
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    
    labels = map(string)
    
    # Update Configuration
    update_config = object({
      max_unavailable_percentage = number
    })
    
    # Launch Template
    enable_monitoring = bool
    
    # Kubernetes
    kubernetes_version = string
  }))
  
  default = {}  # Will be defined in terraform.tfvars
}

# ==============================================================================
# ACCESS CONTROL VARIABLES
# ==============================================================================

variable "platform_team_access" {
  description = "Platform team access configuration"
  type = list(object({
    principal_arn     = string
    kubernetes_groups = optional(list(string), ["system:masters"])
    type             = optional(string, "STANDARD")
  }))
  default = []
  
  validation {
    condition     = length(var.platform_team_access) > 0
    error_message = "Platform team access must be explicitly configured for production."
  }
}

variable "gaming_dev_team_access" {
  description = "Gaming development team access configuration (RESTRICTED IN PROD)"
  type = list(object({
    principal_arn     = string
    kubernetes_groups = optional(list(string), ["gaming:read-only"])
    type             = optional(string, "STANDARD")
  }))
  default = []  # No dev access in production by default
}

# ==============================================================================
# SECURITY VARIABLES
# ==============================================================================

variable "enable_remote_access" {
  description = "Enable remote access to worker nodes"
  type        = bool
  default     = false  # Disabled in production for security
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for SSH access to nodes"
  type        = string
  default     = ""  # Empty by default, must be explicitly set if remote access is enabled
}

variable "create_bastion_host" {
  description = "Whether to create a bastion host"
  type        = bool
  default     = false  # Disabled by default for production security
}

variable "require_mfa" {
  description = "Require MFA for sensitive operations"
  type        = bool
  default     = true  # Mandatory for production
}

variable "external_id" {
  description = "External ID for cross-account access"
  type        = string
  default     = null
}

variable "trusted_aws_accounts" {
  description = "List of trusted AWS account IDs for cross-account access"
  type        = list(string)
  default     = []
}

variable "trusted_role_arns" {
  description = "List of trusted IAM role ARNs for cross-account access"
  type        = list(string)
  default     = []
}

# ==============================================================================
# COMPUTE VARIABLES
# ==============================================================================

variable "enable_spot_instances" {
  description = "Enable spot instances for cost optimization"
  type        = bool
  default     = false  # On-demand for production stability by default
}

variable "enable_gpu_nodes" {
  description = "Enable GPU node groups for advanced gaming features"
  type        = bool
  default     = false  # Optional for production
}

variable "enable_arm_nodes" {
  description = "Enable ARM-based node groups for cost optimization"
  type        = bool
  default     = false  # Optional for production
}

# ==============================================================================
# ENCRYPTION AND SECURITY
# ==============================================================================

variable "enable_multi_region" {
  description = "Enable multi-region KMS keys for disaster recovery"
  type        = bool
  default     = false  # Optional based on DR requirements
}

# ==============================================================================
# NETWORKING FEATURES
# ==============================================================================

variable "enable_vpn_gateway" {
  description = "Enable VPN gateway for the VPC"
  type        = bool
  default     = false  # Optional for production based on connectivity requirements
}

variable "enable_public_access" {
  description = "Enable public access to EKS cluster API"
  type        = bool
  default     = false  # Disabled by default for production security
}

# ==============================================================================
# HIGH AVAILABILITY AND DISASTER RECOVERY
# ==============================================================================

variable "enable_cross_region_backup" {
  description = "Enable cross-region backup for disaster recovery"
  type        = bool
  default     = true  # Enabled for production
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 90  # Extended retention for production
  
  validation {
    condition     = var.backup_retention_days >= 30
    error_message = "Production backup retention must be at least 30 days."
  }
}

variable "enable_monitoring_alerts" {
  description = "Enable comprehensive monitoring and alerting"
  type        = bool
  default     = true  # Mandatory for production
}

# ==============================================================================
# COMPLIANCE AND GOVERNANCE
# ==============================================================================

variable "compliance_framework" {
  description = "Compliance framework requirements"
  type        = string
  default     = "SOC2"
  
  validation {
    condition = contains([
      "SOC2", "PCI-DSS", "HIPAA", "ISO27001", "GDPR"
    ], var.compliance_framework)
    error_message = "Compliance framework must be a supported standard."
  }
}

variable "enable_audit_logging" {
  description = "Enable comprehensive audit logging"
  type        = bool
  default     = true  # Mandatory for production
}

variable "data_residency_requirements" {
  description = "Data residency requirements for compliance"
  type        = string
  default     = "us"
  
  validation {
    condition = contains([
      "us", "eu", "apac", "global"
    ], var.data_residency_requirements)
    error_message = "Data residency must be a valid region."
  }
}

# ==============================================================================
# PERFORMANCE AND SCALING
# ==============================================================================

variable "performance_tier" {
  description = "Performance tier for production workloads"
  type        = string
  default     = "high"
  
  validation {
    condition = contains([
      "standard", "high", "ultra"
    ], var.performance_tier)
    error_message = "Performance tier must be standard, high, or ultra."
  }
}

variable "auto_scaling_target_cpu" {
  description = "Target CPU utilization for auto-scaling"
  type        = number
  default     = 70  # Conservative for production
  
  validation {
    condition     = var.auto_scaling_target_cpu >= 50 && var.auto_scaling_target_cpu <= 90
    error_message = "Auto-scaling target CPU must be between 50% and 90%."
  }
}
# ==============================================================================
# TEST ENVIRONMENT - VARIABLES
# ==============================================================================
# Description: Variable definitions for test environment
# Environment: Test (Production-like but smaller scale, automated testing friendly)
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
  default     = "us-east-1"
  
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
  default     = "engineering-test"
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
  default     = "10.20.0.0/16"  # Test environment VPC
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "authorized_networks" {
  description = "List of authorized CIDR blocks for cluster API access"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "allowed_cidrs" {
  description = "List of CIDR blocks allowed to access load balancer"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Open for testing, restrict in production
}

variable "office_network_cidrs" {
  description = "List of office network CIDR blocks for administrative access"
  type        = list(string)
  default     = ["203.0.113.0/24"]  # Replace with actual office networks
}

# ==============================================================================
# EKS CLUSTER VARIABLES
# ==============================================================================

variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.29"
  
  validation {
    condition = contains([
      "1.27", "1.28", "1.29"
    ], var.eks_cluster_version)
    error_message = "EKS cluster version must be a supported version."
  }
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
}

variable "gaming_dev_team_access" {
  description = "Gaming development team access configuration"
  type = list(object({
    principal_arn     = string
    kubernetes_groups = optional(list(string), ["gaming:developers"])
    type             = optional(string, "STANDARD")
  }))
  default = []
}

# ==============================================================================
# SECURITY VARIABLES
# ==============================================================================

variable "enable_remote_access" {
  description = "Enable remote access to worker nodes"
  type        = bool
  default     = true  # Enabled for test environment debugging
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for SSH access to nodes"
  type        = string
  default     = "test-gaming-nodes"
}

variable "create_bastion_host" {
  description = "Whether to create a bastion host"
  type        = bool
  default     = true
}

# ==============================================================================
# GAMING-SPECIFIC VARIABLES
# ==============================================================================

variable "gaming_traffic_cidrs" {
  description = "CIDR blocks allowed for gaming traffic"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

# ==============================================================================
# COMPUTE VARIABLES
# ==============================================================================

variable "enable_spot_instances" {
  description = "Enable spot instances for cost optimization"
  type        = bool
  default     = true  # Enabled in test for cost optimization
}

variable "enable_gpu_nodes" {
  description = "Enable GPU node groups for advanced gaming features"
  type        = bool
  default     = false  # Disabled in test for cost optimization
}

variable "enable_arm_nodes" {
  description = "Enable ARM-based node groups for cost optimization"
  type        = bool
  default     = true  # Enabled in test to validate ARM compatibility
}

# ==============================================================================
# ENCRYPTION AND SECURITY
# ==============================================================================

variable "enable_multi_region" {
  description = "Enable multi-region KMS keys"
  type        = bool
  default     = false  # Single region for test
}

variable "require_mfa" {
  description = "Require MFA for sensitive operations"
  type        = bool
  default     = false  # Disabled for automated testing
}

variable "external_id" {
  description = "External ID for cross-account access"
  type        = string
  default     = null
}

variable "trusted_aws_accounts" {
  description = "List of trusted AWS account IDs"
  type        = list(string)
  default     = []
}

variable "trusted_role_arns" {
  description = "List of trusted IAM role ARNs"
  type        = list(string)
  default     = []
}

# ==============================================================================
# NETWORKING FEATURES
# ==============================================================================

variable "enable_vpn_gateway" {
  description = "Enable VPN gateway for the VPC"
  type        = bool
  default     = false  # Not needed in test
}

variable "enable_public_access" {
  description = "Enable public access to EKS cluster API"
  type        = bool
  default     = true  # Enabled for test accessibility
}
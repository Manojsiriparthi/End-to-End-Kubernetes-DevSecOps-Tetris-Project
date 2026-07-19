# ==============================================================================
# KMS MODULE - VARIABLES
# ==============================================================================
# Description: Variable definitions for KMS module
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
# KEY CREATION FLAGS
# ==============================================================================

variable "create_eks_key" {
  description = "Create KMS key for EKS cluster encryption"
  type        = bool
  default     = true
}

variable "create_ebs_key" {
  description = "Create KMS key for EBS volume encryption"
  type        = bool
  default     = true
}

variable "create_cloudwatch_logs_key" {
  description = "Create KMS key for CloudWatch Logs encryption"
  type        = bool
  default     = true
}

variable "create_secrets_manager_key" {
  description = "Create KMS key for Secrets Manager encryption"
  type        = bool
  default     = true
}

variable "create_s3_key" {
  description = "Create KMS key for S3 bucket encryption"
  type        = bool
  default     = true
}

variable "create_dynamodb_key" {
  description = "Create KMS key for DynamoDB encryption"
  type        = bool
  default     = true
}

# ==============================================================================
# KEY CONFIGURATION
# ==============================================================================

variable "deletion_window_in_days" {
  description = "Duration in days after which the key is deleted after destruction of the resource"
  type        = number
  default     = 7
  
  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "Deletion window must be between 7 and 30 days."
  }
}

variable "enable_key_rotation" {
  description = "Specifies whether key rotation is enabled"
  type        = bool
  default     = true
}

variable "enable_multi_region" {
  description = "Indicates whether the KMS key is multi-region or regional key"
  type        = bool
  default     = false
}

# ==============================================================================
# ROLE ARNs FOR KEY POLICIES
# ==============================================================================

variable "cluster_service_role_arn" {
  description = "ARN of the EKS cluster service role"
  type        = string
  default     = ""
}

variable "node_group_role_arn" {
  description = "ARN of the EKS node group role"
  type        = string
  default     = ""
}

variable "gaming_role_arn" {
  description = "ARN of the gaming workload role"
  type        = string
  default     = ""
}

# ==============================================================================
# EBS ENCRYPTION DEFAULTS
# ==============================================================================

variable "set_ebs_default_key" {
  description = "Set the created EBS key as the default EBS encryption key"
  type        = bool
  default     = false
}

variable "enable_ebs_encryption_by_default" {
  description = "Enable EBS encryption by default"
  type        = bool
  default     = false
}

# ==============================================================================
# GAMING-SPECIFIC CONFIGURATIONS
# ==============================================================================

variable "gaming_encryption_requirements" {
  description = "Gaming-specific encryption requirements"
  type = object({
    encrypt_session_data    = optional(bool, true)
    encrypt_player_data     = optional(bool, true)
    encrypt_game_assets     = optional(bool, true)
    encrypt_telemetry       = optional(bool, true)
    encrypt_backups         = optional(bool, true)
    high_performance_mode   = optional(bool, false)
  })
  default = {
    encrypt_session_data  = true
    encrypt_player_data   = true
    encrypt_game_assets   = true
    encrypt_telemetry     = true
    encrypt_backups       = true
    high_performance_mode = false
  }
}

# ==============================================================================
# KEY USAGE PERMISSIONS
# ==============================================================================

variable "key_administrators" {
  description = "List of IAM ARNs that can administer the KMS keys"
  type        = list(string)
  default     = []
}

variable "key_users" {
  description = "List of IAM ARNs that can use the KMS keys"
  type        = list(string)
  default     = []
}

variable "cross_account_access" {
  description = "List of AWS account IDs that can access the KMS keys"
  type        = list(string)
  default     = []
}

# ==============================================================================
# ENVIRONMENT-SPECIFIC SETTINGS
# ==============================================================================

variable "environment_config" {
  description = "Environment-specific KMS configurations"
  type = object({
    enable_compliance_logging = optional(bool, false)
    require_encryption        = optional(bool, true)
    key_rotation_interval     = optional(number, 365)
    backup_retention_days     = optional(number, 30)
  })
  default = {
    enable_compliance_logging = false
    require_encryption        = true
    key_rotation_interval     = 365
    backup_retention_days     = 30
  }
}

# ==============================================================================
# CUSTOM KEY POLICIES
# ==============================================================================

variable "custom_key_policies" {
  description = "Custom key policies for specific use cases"
  type = object({
    eks_cluster_policy      = optional(string, "")
    ebs_policy             = optional(string, "")
    cloudwatch_logs_policy = optional(string, "")
    secrets_manager_policy = optional(string, "")
    s3_policy              = optional(string, "")
    dynamodb_policy        = optional(string, "")
  })
  default = {
    eks_cluster_policy      = ""
    ebs_policy             = ""
    cloudwatch_logs_policy = ""
    secrets_manager_policy = ""
    s3_policy              = ""
    dynamodb_policy        = ""
  }
}

# ==============================================================================
# KEY ALIASES
# ==============================================================================

variable "key_aliases" {
  description = "Custom aliases for KMS keys"
  type = object({
    eks_cluster_alias      = optional(string, "")
    ebs_alias             = optional(string, "")
    cloudwatch_logs_alias = optional(string, "")
    secrets_manager_alias = optional(string, "")
    s3_alias              = optional(string, "")
    dynamodb_alias        = optional(string, "")
  })
  default = {
    eks_cluster_alias      = ""
    ebs_alias             = ""
    cloudwatch_logs_alias = ""
    secrets_manager_alias = ""
    s3_alias              = ""
    dynamodb_alias        = ""
  }
}

# ==============================================================================
# SECURITY CONFIGURATIONS
# ==============================================================================

variable "security_config" {
  description = "Security configuration for KMS keys"
  type = object({
    enable_key_grants            = optional(bool, true)
    grant_operations            = optional(list(string), ["Decrypt", "Encrypt", "GenerateDataKey", "ReEncryptFrom", "ReEncryptTo", "CreateGrant", "DescribeKey"])
    enable_via_service_condition = optional(bool, true)
    allowed_services            = optional(list(string), ["eks.amazonaws.com", "ec2.amazonaws.com", "logs.amazonaws.com", "secretsmanager.amazonaws.com", "s3.amazonaws.com", "dynamodb.amazonaws.com"])
  })
  default = {
    enable_key_grants            = true
    grant_operations            = ["Decrypt", "Encrypt", "GenerateDataKey", "ReEncryptFrom", "ReEncryptTo", "CreateGrant", "DescribeKey"]
    enable_via_service_condition = true
    allowed_services            = ["eks.amazonaws.com", "ec2.amazonaws.com", "logs.amazonaws.com", "secretsmanager.amazonaws.com", "s3.amazonaws.com", "dynamodb.amazonaws.com"]
  }
}

# ==============================================================================
# COST OPTIMIZATION
# ==============================================================================

variable "cost_optimization" {
  description = "Cost optimization settings for KMS"
  type = object({
    use_single_key_per_service = optional(bool, false)
    enable_automatic_rotation  = optional(bool, true)
    delete_unused_keys        = optional(bool, false)
    key_usage_tracking        = optional(bool, true)
  })
  default = {
    use_single_key_per_service = false
    enable_automatic_rotation  = true
    delete_unused_keys        = false
    key_usage_tracking        = true
  }
}
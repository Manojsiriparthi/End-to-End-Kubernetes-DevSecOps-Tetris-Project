# ==============================================================================
# IAM MODULE - VARIABLES
# ==============================================================================
# Description: Variable definitions for IAM module
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

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# OIDC PROVIDER CONFIGURATION
# ==============================================================================

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  type        = string
  default     = ""
}

# ==============================================================================
# SERVICE ROLE CREATION FLAGS
# ==============================================================================

variable "create_load_balancer_controller_role" {
  description = "Create IAM role for AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "create_cluster_autoscaler_role" {
  description = "Create IAM role for Cluster Autoscaler"
  type        = bool
  default     = true
}

variable "create_ebs_csi_driver_role" {
  description = "Create IAM role for EBS CSI Driver"
  type        = bool
  default     = true
}

variable "create_external_dns_role" {
  description = "Create IAM role for External DNS"
  type        = bool
  default     = true
}

variable "create_gaming_workload_role" {
  description = "Create IAM role for gaming workload applications"
  type        = bool
  default     = true
}

# ==============================================================================
# MONITORING AND LOGGING
# ==============================================================================

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs IAM permissions"
  type        = bool
  default     = true
}

# ==============================================================================
# GAMING-SPECIFIC CONFIGURATIONS
# ==============================================================================

variable "gaming_features" {
  description = "Gaming-specific feature configurations"
  type = object({
    enable_session_management  = optional(bool, true)
    enable_realtime_metrics   = optional(bool, true)
    enable_auto_scaling       = optional(bool, true)
    enable_websocket_api      = optional(bool, true)
    enable_leaderboards       = optional(bool, true)
  })
  default = {
    enable_session_management = true
    enable_realtime_metrics  = true
    enable_auto_scaling      = true
    enable_websocket_api     = true
    enable_leaderboards      = true
  }
}

# ==============================================================================
# SECURITY CONFIGURATIONS
# ==============================================================================

variable "security_config" {
  description = "Security configuration for IAM roles and policies"
  type = object({
    max_session_duration = optional(number, 3600)
    require_mfa         = optional(bool, false)
    external_id         = optional(string, null)
  })
  default = {
    max_session_duration = 3600
    require_mfa         = false
    external_id         = null
  }
}

# ==============================================================================
# ADDITIONAL AWS SERVICE INTEGRATIONS
# ==============================================================================

variable "aws_services" {
  description = "AWS services integration configuration"
  type = object({
    enable_secrets_manager    = optional(bool, true)
    enable_parameter_store    = optional(bool, true)
    enable_s3_access         = optional(bool, true)
    enable_ses_access        = optional(bool, false)
    enable_sns_access        = optional(bool, true)
    enable_sqs_access        = optional(bool, true)
  })
  default = {
    enable_secrets_manager = true
    enable_parameter_store = true
    enable_s3_access      = true
    enable_ses_access     = false
    enable_sns_access     = true
    enable_sqs_access     = true
  }
}

# ==============================================================================
# CUSTOM POLICY CONFIGURATIONS
# ==============================================================================

variable "custom_policies" {
  description = "List of custom policy ARNs to attach to roles"
  type = object({
    cluster_service_role_policies = optional(list(string), [])
    node_group_role_policies      = optional(list(string), [])
    gaming_workload_policies      = optional(list(string), [])
  })
  default = {
    cluster_service_role_policies = []
    node_group_role_policies      = []
    gaming_workload_policies      = []
  }
}

# ==============================================================================
# ROLE TRUST RELATIONSHIPS
# ==============================================================================

variable "trusted_role_arns" {
  description = "List of IAM role ARNs that can assume gaming workload roles"
  type        = list(string)
  default     = []
}

variable "trusted_aws_accounts" {
  description = "List of AWS account IDs that can assume roles for cross-account access"
  type        = list(string)
  default     = []
}

# ==============================================================================
# SERVICE ACCOUNT CONFIGURATIONS
# ==============================================================================

variable "service_accounts" {
  description = "Configuration for Kubernetes service accounts"
  type = object({
    load_balancer_controller = optional(object({
      namespace = string
      name      = string
    }), {
      namespace = "kube-system"
      name      = "aws-load-balancer-controller"
    })
    cluster_autoscaler = optional(object({
      namespace = string
      name      = string
    }), {
      namespace = "kube-system"
      name      = "cluster-autoscaler"
    })
    ebs_csi_driver = optional(object({
      namespace = string
      name      = string
    }), {
      namespace = "kube-system"
      name      = "ebs-csi-controller-sa"
    })
    external_dns = optional(object({
      namespace = string
      name      = string
    }), {
      namespace = "kube-system"
      name      = "external-dns"
    })
    gaming_workload = optional(object({
      namespace = string
      name      = string
    }), {
      namespace = "gaming"
      name      = "tetris-app"
    })
  })
  default = {
    load_balancer_controller = {
      namespace = "kube-system"
      name      = "aws-load-balancer-controller"
    }
    cluster_autoscaler = {
      namespace = "kube-system"
      name      = "cluster-autoscaler"
    }
    ebs_csi_driver = {
      namespace = "kube-system"
      name      = "ebs-csi-controller-sa"
    }
    external_dns = {
      namespace = "kube-system"
      name      = "external-dns"
    }
    gaming_workload = {
      namespace = "gaming"
      name      = "tetris-app"
    }
  }
}

# ==============================================================================
# RESOURCE NAMING
# ==============================================================================

variable "role_name_override" {
  description = "Override default role names"
  type = object({
    cluster_service_role          = optional(string, null)
    node_group_role              = optional(string, null)
    load_balancer_controller_role = optional(string, null)
    cluster_autoscaler_role      = optional(string, null)
    ebs_csi_driver_role          = optional(string, null)
    external_dns_role            = optional(string, null)
    gaming_workload_role         = optional(string, null)
  })
  default = {
    cluster_service_role          = null
    node_group_role              = null
    load_balancer_controller_role = null
    cluster_autoscaler_role      = null
    ebs_csi_driver_role          = null
    external_dns_role            = null
    gaming_workload_role         = null
  }
}

# ==============================================================================
# ENVIRONMENT-SPECIFIC CONFIGURATIONS
# ==============================================================================

variable "environment_config" {
  description = "Environment-specific IAM configurations"
  type = object({
    enable_debug_policies     = optional(bool, false)
    enable_admin_access       = optional(bool, false)
    restrict_to_region        = optional(bool, true)
    enable_cost_monitoring    = optional(bool, true)
  })
  default = {
    enable_debug_policies  = false
    enable_admin_access    = false
    restrict_to_region     = true
    enable_cost_monitoring = true
  }
}
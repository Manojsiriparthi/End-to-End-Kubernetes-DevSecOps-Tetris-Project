# ==============================================================================
# EKS ADDONS DEV ENVIRONMENT - VARIABLES
# ==============================================================================
# Description: Variable definitions for EKS addons development environment
# Environment: Development
# Author: Platform Engineering Team
# Version: 2.0.0
# ==============================================================================

# ==============================================================================
# CORE VARIABLES
# ==============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "tetris-platform"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "engineering-dev"
}

# ==============================================================================
# INFRASTRUCTURE STATE CONFIGURATION
# ==============================================================================

variable "infrastructure_state_bucket" {
  description = "S3 bucket containing infrastructure Terraform state"
  type        = string
  default     = "tetris-platform-terraform-state-dev"
}

variable "infrastructure_state_key" {
  description = "S3 key for infrastructure Terraform state"
  type        = string
  default     = "gaming-infrastructure/dev/terraform.tfstate"
}

# ==============================================================================
# ADDON CONFIGURATION FLAGS
# ==============================================================================

variable "enable_metrics_server" {
  description = "Enable Metrics Server addon"
  type        = bool
  default     = true  # Essential for HPA
}

variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = true  # Essential for gaming ALB/NLB
}

variable "enable_cluster_autoscaler" {
  description = "Enable Cluster Autoscaler"
  type        = bool
  default     = true  # Essential for gaming auto-scaling
}

variable "enable_hpa" {
  description = "Enable Horizontal Pod Autoscaler configurations"
  type        = bool
  default     = true  # Essential for gaming workload scaling
}

variable "enable_ebs_csi_driver" {
  description = "Enable EBS CSI Driver"
  type        = bool
  default     = true  # Essential for persistent storage
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch Logs integration"
  type        = bool
  default     = true  # Minimal logging for dev
}

variable "enable_external_dns" {
  description = "Enable External DNS"
  type        = bool
  default     = false  # Disabled for dev cost optimization
}

variable "enable_karpenter" {
  description = "Enable Karpenter node provisioner"
  type        = bool
  default     = false  # Disabled for dev - using Cluster Autoscaler
}

variable "enable_vpa" {
  description = "Enable Vertical Pod Autoscaler"
  type        = bool
  default     = false  # Disabled for dev resource optimization
}

variable "enable_gateway_api" {
  description = "Enable Gateway API"
  type        = bool
  default     = false  # Disabled for dev - using traditional ingress
}

# ==============================================================================
# GAMING-SPECIFIC CONFIGURATIONS
# ==============================================================================

variable "gaming_config" {
  description = "Gaming-specific configurations for addons"
  type = object({
    # Load balancer configurations
    websocket_timeout_seconds = optional(number, 300)
    session_affinity_enabled  = optional(bool, true)
    cross_zone_load_balancing = optional(bool, true)
    
    # Auto-scaling configurations
    scale_down_delay_minutes        = optional(number, 5)
    max_node_provision_time_minutes = optional(number, 10)
    new_pod_scale_up_delay_seconds  = optional(number, 30)
    
    # HPA configurations
    default_target_cpu_percent = optional(number, 70)
    websocket_connections_per_pod = optional(number, 100)
    active_sessions_per_pod = optional(number, 50)
    
    # Storage configurations
    default_storage_iops = optional(number, 3000)
    fast_storage_iops   = optional(number, 4000)
  })
  default = {
    websocket_timeout_seconds       = 300
    session_affinity_enabled        = true
    cross_zone_load_balancing      = true
    scale_down_delay_minutes       = 5
    max_node_provision_time_minutes = 10
    new_pod_scale_up_delay_seconds = 30
    default_target_cpu_percent     = 70
    websocket_connections_per_pod  = 100
    active_sessions_per_pod        = 50
    default_storage_iops          = 3000
    fast_storage_iops             = 4000
  }
}

# ==============================================================================
# MONITORING AND LOGGING
# ==============================================================================

variable "monitoring_config" {
  description = "Monitoring and logging configuration"
  type = object({
    log_retention_days = optional(number, 3)
    enable_fluent_bit = optional(bool, false)
    metrics_resolution_seconds = optional(number, 60)
  })
  default = {
    log_retention_days         = 3
    enable_fluent_bit         = false
    metrics_resolution_seconds = 60
  }
}

# ==============================================================================
# RESOURCE CONFIGURATIONS
# ==============================================================================

variable "resource_configs" {
  description = "Resource configurations for addons in dev environment"
  type = object({
    # Metrics Server
    metrics_server = optional(object({
      replicas = optional(number, 1)
      cpu_request = optional(string, "50m")
      memory_request = optional(string, "64Mi")
      cpu_limit = optional(string, "100m")
      memory_limit = optional(string, "128Mi")
    }), {})
    
    # AWS Load Balancer Controller
    aws_load_balancer_controller = optional(object({
      replicas = optional(number, 1)
      cpu_request = optional(string, "100m")
      memory_request = optional(string, "128Mi")
      cpu_limit = optional(string, "200m")
      memory_limit = optional(string, "256Mi")
    }), {})
    
    # Cluster Autoscaler
    cluster_autoscaler = optional(object({
      replicas = optional(number, 1)
      cpu_request = optional(string, "100m")
      memory_request = optional(string, "128Mi")
      cpu_limit = optional(string, "200m")
      memory_limit = optional(string, "256Mi")
    }), {})
    
    # EBS CSI Driver
    ebs_csi_driver = optional(object({
      controller_replicas = optional(number, 1)
      cpu_request = optional(string, "50m")
      memory_request = optional(string, "64Mi")
      cpu_limit = optional(string, "100m")
      memory_limit = optional(string, "128Mi")
    }), {})
  })
  default = {
    metrics_server = {
      replicas = 1
      cpu_request = "50m"
      memory_request = "64Mi"
      cpu_limit = "100m"
      memory_limit = "128Mi"
    }
    aws_load_balancer_controller = {
      replicas = 1
      cpu_request = "100m"
      memory_request = "128Mi"
      cpu_limit = "200m"
      memory_limit = "256Mi"
    }
    cluster_autoscaler = {
      replicas = 1
      cpu_request = "100m"
      memory_request = "128Mi"
      cpu_limit = "200m"
      memory_limit = "256Mi"
    }
    ebs_csi_driver = {
      controller_replicas = 1
      cpu_request = "50m"
      memory_request = "64Mi"
      cpu_limit = "100m"
      memory_limit = "128Mi"
    }
  }
}
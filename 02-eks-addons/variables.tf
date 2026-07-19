# ==============================================================================
# EKS ADDONS - VARIABLES
# ==============================================================================
# Description: Variables for universal EKS addon deployment
# Author: Platform Engineering Team
# Version: 1.0.0
# Gaming Application: Real-time Tetris Platform
# ==============================================================================

# ==============================================================================
# CORE CONFIGURATION
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
  default     = "us-west-2"
}

# ==============================================================================
# INFRASTRUCTURE STATE CONFIGURATION
# ==============================================================================

variable "infrastructure_state_bucket" {
  description = "S3 bucket containing the infrastructure state"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9.-]+$", var.infrastructure_state_bucket))
    error_message = "S3 bucket name must be valid."
  }
}

variable "infrastructure_state_key" {
  description = "S3 key for the infrastructure state file"
  type        = string
  default     = "infrastructure/terraform.tfstate"
}

# ==============================================================================
# GAMING-SPECIFIC CONFIGURATION
# ==============================================================================

variable "gaming_dns_zones" {
  description = "DNS zones for gaming services"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for zone in var.gaming_dns_zones : can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", zone))
    ])
    error_message = "All DNS zones must be valid domain names."
  }
}

variable "gaming_application_config" {
  description = "Gaming application specific configuration"
  type = object({
    max_concurrent_players     = number
    websocket_timeout_seconds  = number
    session_affinity_duration  = number
    real_time_metrics_interval = number
    game_session_timeout       = number
    auto_scaling_target_cpu    = number
    auto_scaling_target_memory = number
  })
  
  default = {
    max_concurrent_players     = 10000   # Will be overridden per environment
    websocket_timeout_seconds  = 300     # 5 minutes
    session_affinity_duration  = 3600    # 1 hour
    real_time_metrics_interval = 10      # 10 seconds
    game_session_timeout       = 1800    # 30 minutes
    auto_scaling_target_cpu    = 70      # 70% CPU target
    auto_scaling_target_memory = 80      # 80% memory target
  }
}

# ==============================================================================
# AWS LOAD BALANCER CONTROLLER CONFIGURATION
# ==============================================================================

variable "aws_load_balancer_controller_config" {
  description = "AWS Load Balancer Controller configuration"
  type = object({
    replica_count              = number
    enable_waf_v2             = bool
    enable_shield_advanced    = bool
    enable_websocket_support  = bool
    enable_session_affinity   = bool
    ingress_class_name        = string
    default_ssl_policy        = string
  })
  
  default = {
    replica_count              = 2
    enable_waf_v2             = false
    enable_shield_advanced    = false
    enable_websocket_support  = true
    enable_session_affinity   = true
    ingress_class_name        = "alb"
    default_ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  }
}

# ==============================================================================
# GATEWAY API CONFIGURATION
# ==============================================================================

variable "gateway_api_config" {
  description = "Gateway API configuration"
  type = object({
    gateway_class_name         = string
    enable_rate_limiting       = bool
    enable_circuit_breaker     = bool
    enable_websocket_routing   = bool
    enable_real_time_metrics   = bool
    default_timeout_seconds    = number
    max_requests_per_second    = number
  })
  
  default = {
    gateway_class_name         = "gaming-gateway"
    enable_rate_limiting       = true
    enable_circuit_breaker     = true
    enable_websocket_routing   = true
    enable_real_time_metrics   = true
    default_timeout_seconds    = 30
    max_requests_per_second    = 1000
  }
}

# ==============================================================================
# KARPENTER CONFIGURATION
# ==============================================================================

variable "karpenter_config" {
  description = "Karpenter node provisioning configuration"
  type = object({
    max_nodes_per_nodepool     = number
    instance_families          = list(string)
    instance_sizes            = list(string)
    cpu_architecture          = list(string)
    capacity_types            = list(string)
    enable_spot_instances     = bool
    spot_max_price_percentage = number
  })
  
  default = {
    max_nodes_per_nodepool     = 50
    instance_families          = ["m5", "m5a", "m5n", "c5", "c5n", "r5", "r5a"]
    instance_sizes            = ["large", "xlarge", "2xlarge", "4xlarge"]
    cpu_architecture          = ["amd64"]
    capacity_types            = ["spot", "on-demand"]
    enable_spot_instances     = true
    spot_max_price_percentage = 60  # 60% of on-demand price
  }
}

# ==============================================================================
# AUTO-SCALING CONFIGURATION
# ==============================================================================

variable "horizontal_pod_autoscaler_config" {
  description = "HPA configuration for gaming workloads"
  type = object({
    max_replicas                    = number
    min_replicas                    = number
    target_cpu_utilization         = number
    target_memory_utilization      = number
    scale_up_stabilization_seconds  = number
    scale_down_stabilization_seconds = number
    
    # Gaming-specific metrics
    active_connections_per_pod      = number
    active_game_sessions_per_pod    = number
    websocket_connections_per_pod   = number
    response_time_threshold_ms      = number
  })
  
  default = {
    max_replicas                    = 20
    min_replicas                    = 2
    target_cpu_utilization         = 70
    target_memory_utilization      = 80
    scale_up_stabilization_seconds  = 60
    scale_down_stabilization_seconds = 300
    
    # Gaming-specific defaults
    active_connections_per_pod      = 1000
    active_game_sessions_per_pod    = 500
    websocket_connections_per_pod   = 800
    response_time_threshold_ms      = 100
  }
}

variable "vertical_pod_autoscaler_config" {
  description = "VPA configuration for gaming workloads"
  type = object({
    enable_gaming_recommendations = bool
    enable_real_time_updates     = bool
    update_mode                  = string  # "Off", "Initial", "Recreation", "Auto"
    
    # Gaming workload resource limits
    game_server_min_cpu         = string
    game_server_max_cpu         = string
    game_server_min_memory      = string
    game_server_max_memory      = string
    
    websocket_handler_min_cpu   = string
    websocket_handler_max_cpu   = string
    websocket_handler_min_memory = string
    websocket_handler_max_memory = string
  })
  
  default = {
    enable_gaming_recommendations = true
    enable_real_time_updates     = true
    update_mode                  = "Recreation"  # Safe for gaming workloads
    
    # Game server resources
    game_server_min_cpu         = "100m"
    game_server_max_cpu         = "2000m"
    game_server_min_memory      = "128Mi"
    game_server_max_memory      = "4Gi"
    
    # WebSocket handler resources
    websocket_handler_min_cpu   = "50m"
    websocket_handler_max_cpu   = "1000m"
    websocket_handler_min_memory = "64Mi"
    websocket_handler_max_memory = "2Gi"
  }
}

# ==============================================================================
# METRICS AND MONITORING CONFIGURATION
# ==============================================================================

variable "metrics_server_config" {
  description = "Metrics server configuration"
  type = object({
    enable_high_frequency_metrics = bool
    metrics_resolution_seconds    = number
    enable_network_metrics        = bool
    enable_websocket_metrics      = bool
    enable_session_metrics        = bool
    enable_latency_metrics        = bool
  })
  
  default = {
    enable_high_frequency_metrics = true
    metrics_resolution_seconds    = 15
    enable_network_metrics        = true
    enable_websocket_metrics      = true
    enable_session_metrics        = true
    enable_latency_metrics        = true
  }
}

variable "cloudwatch_config" {
  description = "CloudWatch monitoring configuration"
  type = object({
    log_retention_days          = number
    enable_gaming_metrics       = bool
    enable_performance_insights = bool
    enable_custom_dashboards    = bool
    
    # Gaming-specific dashboards
    enable_player_metrics_dashboard    = bool
    enable_game_performance_dashboard  = bool
    enable_websocket_monitoring_dashboard = bool
    enable_session_analytics_dashboard = bool
  })
  
  default = {
    log_retention_days          = 30
    enable_gaming_metrics       = true
    enable_performance_insights = true
    enable_custom_dashboards    = true
    
    # Gaming dashboards
    enable_player_metrics_dashboard    = true
    enable_game_performance_dashboard  = true
    enable_websocket_monitoring_dashboard = true
    enable_session_analytics_dashboard = true
  }
}

# ==============================================================================
# STORAGE CONFIGURATION
# ==============================================================================

variable "ebs_csi_config" {
  description = "EBS CSI driver configuration"
  type = object({
    enable_gp3_by_default        = bool
    enable_fast_snapshot_restore = bool
    enable_volume_encryption     = bool
    
    # Gaming storage classes
    game_data_iops              = number
    game_data_throughput        = number
    session_state_iops          = number
    session_state_type          = string
  })
  
  default = {
    enable_gp3_by_default        = true
    enable_fast_snapshot_restore = false  # Will be overridden per environment
    enable_volume_encryption     = true
    
    # Gaming storage performance
    game_data_iops              = 8000
    game_data_throughput        = 500
    session_state_iops          = 16000
    session_state_type          = "io2"
  }
}

variable "efs_csi_config" {
  description = "EFS CSI driver configuration"
  type = object({
    performance_mode = string  # "generalPurpose" or "maxIO"
    throughput_mode  = string  # "bursting" or "provisioned"
    encrypted        = bool
    provisioned_throughput_in_mibps = number
  })
  
  default = {
    performance_mode = "generalPurpose"
    throughput_mode  = "bursting"
    encrypted        = true
    provisioned_throughput_in_mibps = 500
  }
}

# ==============================================================================
# NETWORK AND DNS CONFIGURATION
# ==============================================================================

variable "external_dns_config" {
  description = "External DNS configuration"
  type = object({
    txt_owner_id     = string
    policy          = string  # "sync" or "upsert-only"
    registry        = string  # "txt" or "noop"
    interval        = string
  })
  
  default = {
    txt_owner_id     = "tetris-platform-external-dns"
    policy          = "upsert-only"  # Safer for production
    registry        = "txt"
    interval        = "1m"
  }
}

# ==============================================================================
# FALLBACK CONFIGURATION
# ==============================================================================

variable "enable_cluster_autoscaler_fallback" {
  description = "Enable cluster autoscaler as fallback to Karpenter"
  type        = bool
  default     = false
}

variable "cluster_autoscaler_config" {
  description = "Cluster autoscaler configuration (fallback to Karpenter)"
  type = object({
    scale_down_delay_after_add       = string
    scale_down_unneeded_time         = string
    scale_down_utilization_threshold = number
    skip_nodes_with_local_storage   = bool
    skip_nodes_with_system_pods     = bool
  })
  
  default = {
    scale_down_delay_after_add       = "2m"
    scale_down_unneeded_time         = "5m"
    scale_down_utilization_threshold = 0.6
    skip_nodes_with_local_storage   = false
    skip_nodes_with_system_pods     = false
  }
}

# ==============================================================================
# SECURITY CONFIGURATION
# ==============================================================================

variable "security_config" {
  description = "Security configuration for gaming workloads"
  type = object({
    enable_pod_security_standards = bool
    enable_network_policies       = bool
    enable_service_mesh          = bool
    default_security_context     = object({
      run_as_non_root        = bool
      read_only_root_filesystem = bool
      allow_privilege_escalation = bool
    })
  })
  
  default = {
    enable_pod_security_standards = true
    enable_network_policies       = true
    enable_service_mesh          = false  # Can be enabled per environment
    default_security_context = {
      run_as_non_root        = true
      read_only_root_filesystem = true
      allow_privilege_escalation = false
    }
  }
}
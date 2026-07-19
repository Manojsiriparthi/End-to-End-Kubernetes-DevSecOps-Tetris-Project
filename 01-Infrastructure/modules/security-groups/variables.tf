# ==============================================================================
# SECURITY GROUPS MODULE - VARIABLES
# ==============================================================================
# Description: Variable definitions for security groups module
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
# VPC CONFIGURATION
# ==============================================================================

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = []
}

# ==============================================================================
# NETWORK ACCESS CONTROL
# ==============================================================================

variable "authorized_networks" {
  description = "List of authorized CIDR blocks for cluster API access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_cidrs" {
  description = "List of CIDR blocks allowed to access load balancer"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "office_network_cidrs" {
  description = "List of office network CIDR blocks for administrative access"
  type        = list(string)
  default     = []
}

# ==============================================================================
# GAMING FEATURES
# ==============================================================================

variable "enable_gaming_traffic" {
  description = "Enable gaming-specific traffic rules"
  type        = bool
  default     = true
}

variable "enable_websocket_traffic" {
  description = "Enable WebSocket traffic for real-time gaming"
  type        = bool
  default     = true
}

variable "enable_public_access" {
  description = "Enable public access to gaming applications"
  type        = bool
  default     = true
}

variable "enable_gaming_metrics" {
  description = "Enable gaming metrics collection"
  type        = bool
  default     = true
}

# ==============================================================================
# SECURITY GROUP CREATION FLAGS
# ==============================================================================

variable "create_database_security_group" {
  description = "Create database security group"
  type        = bool
  default     = true
}

variable "create_redis_security_group" {
  description = "Create Redis/ElastiCache security group"
  type        = bool
  default     = true
}

variable "create_monitoring_security_group" {
  description = "Create monitoring security group"
  type        = bool
  default     = true
}

variable "create_bastion_security_group" {
  description = "Create bastion host security group"
  type        = bool
  default     = false
}

# ==============================================================================
# DATABASE CONFIGURATION
# ==============================================================================

variable "enable_postgresql" {
  description = "Enable PostgreSQL access rules"
  type        = bool
  default     = false
}

variable "enable_redis_cluster" {
  description = "Enable Redis cluster mode access"
  type        = bool
  default     = false
}

# ==============================================================================
# GAMING-SPECIFIC PORT CONFIGURATION
# ==============================================================================

variable "gaming_ports" {
  description = "Gaming-specific port configuration"
  type = object({
    websocket_base_port    = optional(number, 8080)
    websocket_port_range   = optional(number, 10)
    game_api_port         = optional(number, 3000)
    metrics_port          = optional(number, 9090)
    health_check_port     = optional(number, 8081)
    admin_port            = optional(number, 9000)
  })
  default = {
    websocket_base_port  = 8080
    websocket_port_range = 10
    game_api_port       = 3000
    metrics_port        = 9090
    health_check_port   = 8081
    admin_port          = 9000
  }
}

# ==============================================================================
# CUSTOM SECURITY RULES
# ==============================================================================

variable "custom_ingress_rules" {
  description = "List of custom ingress rules for gaming applications"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string), [])
    security_groups = optional(list(string), [])
    description     = string
  }))
  default = []
}

variable "custom_egress_rules" {
  description = "List of custom egress rules for gaming applications"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string), [])
    security_groups = optional(list(string), [])
    description     = string
  }))
  default = []
}

# ==============================================================================
# ENVIRONMENT-SPECIFIC CONFIGURATIONS
# ==============================================================================

variable "environment_config" {
  description = "Environment-specific security configurations"
  type = object({
    enable_strict_security    = optional(bool, false)
    enable_debug_access      = optional(bool, false)
    enable_admin_access      = optional(bool, false)
    restrict_ssh_access      = optional(bool, true)
    enable_flow_logs         = optional(bool, true)
  })
  default = {
    enable_strict_security = false
    enable_debug_access   = false
    enable_admin_access   = false
    restrict_ssh_access   = true
    enable_flow_logs      = true
  }
}

# ==============================================================================
# LOAD BALANCER CONFIGURATION
# ==============================================================================

variable "load_balancer_config" {
  description = "Load balancer security configuration"
  type = object({
    enable_http_redirect     = optional(bool, true)
    enable_ssl_termination   = optional(bool, true)
    enable_waf              = optional(bool, false)
    custom_headers          = optional(list(string), [])
  })
  default = {
    enable_http_redirect   = true
    enable_ssl_termination = true
    enable_waf            = false
    custom_headers        = []
  }
}

# ==============================================================================
# COMPLIANCE AND SECURITY
# ==============================================================================

variable "security_compliance" {
  description = "Security compliance configuration"
  type = object({
    require_ssl             = optional(bool, true)
    enable_security_groups_logging = optional(bool, true)
    restrict_default_sg     = optional(bool, true)
    enable_nacls           = optional(bool, false)
  })
  default = {
    require_ssl                    = true
    enable_security_groups_logging = true
    restrict_default_sg           = true
    enable_nacls                  = false
  }
}

# ==============================================================================
# REGIONAL CONFIGURATION
# ==============================================================================

variable "regional_config" {
  description = "Regional-specific configurations"
  type = object({
    enable_cross_az_traffic    = optional(bool, true)
    enable_multi_region_access = optional(bool, false)
    preferred_azs             = optional(list(string), [])
  })
  default = {
    enable_cross_az_traffic    = true
    enable_multi_region_access = false
    preferred_azs             = []
  }
}

# ==============================================================================
# GAMING PERFORMANCE OPTIMIZATIONS
# ==============================================================================

variable "gaming_optimizations" {
  description = "Gaming performance optimizations for security groups"
  type = object({
    enable_low_latency_rules   = optional(bool, true)
    enable_session_affinity    = optional(bool, true)
    enable_connection_pooling  = optional(bool, true)
    websocket_timeout         = optional(number, 3600)
    max_connections_per_ip    = optional(number, 1000)
  })
  default = {
    enable_low_latency_rules  = true
    enable_session_affinity   = true
    enable_connection_pooling = true
    websocket_timeout        = 3600
    max_connections_per_ip   = 1000
  }
}
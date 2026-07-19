# ==============================================================================
# NETWORKING MODULE - VARIABLES
# ==============================================================================
# Description: Variable definitions for networking module
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

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

# ==============================================================================
# AVAILABILITY ZONES AND SUBNETS
# ==============================================================================

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones must be specified for high availability."
  }
  
  validation {
    condition     = length(var.availability_zones) <= 3
    error_message = "Maximum 3 availability zones are supported by this module."
  }
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  
  validation {
    condition = alltrue([
      for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All public subnet CIDRs must be valid IPv4 CIDR blocks."
  }
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  
  validation {
    condition = alltrue([
      for cidr in var.private_subnet_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All private subnet CIDRs must be valid IPv4 CIDR blocks."
  }
}

variable "database_subnet_cidrs" {
  description = "List of CIDR blocks for database subnets"
  type        = list(string)
  
  validation {
    condition = alltrue([
      for cidr in var.database_subnet_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All database subnet CIDRs must be valid IPv4 CIDR blocks."
  }
}

# ==============================================================================
# NAT GATEWAY CONFIGURATION
# ==============================================================================

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single shared NAT Gateway across all private networks"
  type        = bool
  default     = false
  
  validation {
    condition = var.enable_nat_gateway == true || var.single_nat_gateway == false
    error_message = "single_nat_gateway can only be true when enable_nat_gateway is true."
  }
}

# ==============================================================================
# VPN GATEWAY CONFIGURATION
# ==============================================================================

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway for the VPC"
  type        = bool
  default     = false
}

# ==============================================================================
# DATABASE CONFIGURATION
# ==============================================================================

variable "create_database_subnet_group" {
  description = "Create database subnet group"
  type        = bool
  default     = true
}

# ==============================================================================
# LOGGING AND MONITORING
# ==============================================================================

variable "enable_flow_logs" {
  description = "Enable VPC flow logs"
  type        = bool
  default     = false
}

variable "flow_logs_retention_in_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group"
  type        = number
  default     = 30
  
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.flow_logs_retention_in_days)
    error_message = "Flow logs retention must be a valid CloudWatch log group retention period."
  }
}

# ==============================================================================
# NETWORK SECURITY
# ==============================================================================

variable "enable_network_firewall" {
  description = "Enable AWS Network Firewall for advanced network protection"
  type        = bool
  default     = false
}

variable "network_firewall_policy_arn" {
  description = "ARN of the network firewall policy to attach"
  type        = string
  default     = null
}

# ==============================================================================
# CUSTOM ROUTE CONFIGURATION
# ==============================================================================

variable "custom_public_routes" {
  description = "Additional routes for public route table"
  type = list(object({
    destination_cidr_block = string
    gateway_id            = optional(string)
    nat_gateway_id        = optional(string)
    network_interface_id  = optional(string)
    transit_gateway_id    = optional(string)
    vpc_peering_connection_id = optional(string)
  }))
  default = []
}

variable "custom_private_routes" {
  description = "Additional routes for private route tables"
  type = list(object({
    destination_cidr_block = string
    gateway_id            = optional(string)
    nat_gateway_id        = optional(string)
    network_interface_id  = optional(string)
    transit_gateway_id    = optional(string)
    vpc_peering_connection_id = optional(string)
  }))
  default = []
}

# ==============================================================================
# DHCP OPTIONS
# ==============================================================================

variable "enable_dhcp_options" {
  description = "Enable custom DHCP options set"
  type        = bool
  default     = false
}

variable "dhcp_options_domain_name" {
  description = "Domain name for DHCP options set"
  type        = string
  default     = null
}

variable "dhcp_options_domain_name_servers" {
  description = "List of domain name servers for DHCP options set"
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

variable "dhcp_options_ntp_servers" {
  description = "List of NTP servers for DHCP options set"
  type        = list(string)
  default     = []
}

# ==============================================================================
# NETWORK ACL CONFIGURATION
# ==============================================================================

variable "manage_default_network_acl" {
  description = "Manage the default network ACL"
  type        = bool
  default     = true
}

variable "public_dedicated_network_acl" {
  description = "Whether to use dedicated network ACL (not default) and custom rules for public subnets"
  type        = bool
  default     = false
}

variable "private_dedicated_network_acl" {
  description = "Whether to use dedicated network ACL (not default) and custom rules for private subnets"
  type        = bool
  default     = false
}

variable "database_dedicated_network_acl" {
  description = "Whether to use dedicated network ACL (not default) and custom rules for database subnets"
  type        = bool
  default     = true
}

# ==============================================================================
# SECURITY GROUP DEFAULTS
# ==============================================================================

variable "manage_default_security_group" {
  description = "Manage the default security group"
  type        = bool
  default     = true
}

variable "default_security_group_ingress" {
  description = "List of maps of ingress rules to set on the default security group"
  type        = list(map(string))
  default     = []
}

variable "default_security_group_egress" {
  description = "List of maps of egress rules to set on the default security group"
  type        = list(map(string))
  default = [{
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = "0.0.0.0/0"
  }]
}

# ==============================================================================
# COST OPTIMIZATION
# ==============================================================================

variable "enable_s3_endpoint" {
  description = "Enable S3 VPC endpoint for cost optimization"
  type        = bool
  default     = true
}

variable "enable_dynamodb_endpoint" {
  description = "Enable DynamoDB VPC endpoint for cost optimization"
  type        = bool
  default     = true
}

variable "enable_ec2_endpoint" {
  description = "Enable EC2 VPC endpoint for cost optimization"
  type        = bool
  default     = false
}
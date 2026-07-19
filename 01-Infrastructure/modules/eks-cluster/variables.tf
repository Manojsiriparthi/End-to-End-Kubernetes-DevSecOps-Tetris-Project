# ==============================================================================
# EKS CLUSTER MODULE - VARIABLES
# ==============================================================================
# Description: Variable definitions for EKS cluster module
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
# CLUSTER CONFIGURATION
# ==============================================================================

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "cluster_service_role_arn" {
  description = "ARN of the IAM role that provides permissions for the cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the cluster"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for worker nodes"
  type        = list(string)
  default     = []
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "additional_security_group_ids" {
  description = "List of additional security group IDs to associate with the cluster"
  type        = list(string)
  default     = []
}

# ==============================================================================
# ENCRYPTION CONFIGURATION
# ==============================================================================

variable "kms_key_arn" {
  description = "ARN of the KMS key to use for cluster encryption"
  type        = string
  default     = ""
}

variable "kms_key_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 7
}

# ==============================================================================
# LOGGING CONFIGURATION
# ==============================================================================

variable "enable_gaming_logs" {
  description = "Enable comprehensive logging for gaming analytics"
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain log events in CloudWatch logs"
  type        = number
  default     = 7
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "KMS key ID for encrypting CloudWatch logs"
  type        = string
  default     = ""
}

# ==============================================================================
# EKS ADDONS CONFIGURATION
# ==============================================================================

variable "enable_vpc_cni_addon" {
  description = "Enable VPC CNI addon"
  type        = bool
  default     = true
}

variable "vpc_cni_addon_version" {
  description = "Version of the VPC CNI addon"
  type        = string
  default     = null
}

variable "enable_coredns_addon" {
  description = "Enable CoreDNS addon"
  type        = bool
  default     = true
}

variable "coredns_addon_version" {
  description = "Version of the CoreDNS addon"
  type        = string
  default     = null
}

variable "enable_kube_proxy_addon" {
  description = "Enable kube-proxy addon"
  type        = bool
  default     = true
}

variable "kube_proxy_addon_version" {
  description = "Version of the kube-proxy addon"
  type        = string
  default     = null
}

variable "enable_ebs_csi_driver_addon" {
  description = "Enable EBS CSI driver addon"
  type        = bool
  default     = true
}

variable "ebs_csi_driver_addon_version" {
  description = "Version of the EBS CSI driver addon"
  type        = string
  default     = null
}

variable "ebs_csi_driver_role_arn" {
  description = "ARN of the IAM role for EBS CSI driver"
  type        = string
  default     = ""
}

variable "enable_efs_csi_driver_addon" {
  description = "Enable EFS CSI driver addon"
  type        = bool
  default     = false
}

variable "efs_csi_driver_addon_version" {
  description = "Version of the EFS CSI driver addon"
  type        = string
  default     = null
}

variable "efs_csi_driver_role_arn" {
  description = "ARN of the IAM role for EFS CSI driver"
  type        = string
  default     = ""
}

# ==============================================================================
# CLUSTER UPGRADE POLICY
# ==============================================================================

variable "cluster_upgrade_policy" {
  description = "Cluster upgrade policy configuration"
  type = object({
    support_type = optional(string, null)
  })
  default = {
    support_type = null
  }
}

# ==============================================================================
# ACCESS CONTROL
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
# GAMING OPTIMIZATIONS
# ==============================================================================

variable "gaming_optimizations" {
  description = "Gaming-specific optimizations for the cluster"
  type = object({
    enable_prefix_delegation = optional(bool, true)
    warm_prefix_target      = optional(string, "1")
    warm_ip_target         = optional(string, "10")
    minimum_ip_target      = optional(string, "3")
    enable_pod_eni         = optional(bool, false)
    enable_fast_dns        = optional(bool, true)
    kube_proxy_mode        = optional(string, "iptables")
  })
  default = {
    enable_prefix_delegation = true
    warm_prefix_target      = "1"
    warm_ip_target         = "10"
    minimum_ip_target      = "3"
    enable_pod_eni         = false
    enable_fast_dns        = true
    kube_proxy_mode        = "iptables"
  }
}

# ==============================================================================
# SECURITY CONFIGURATION
# ==============================================================================

variable "enable_gaming_traffic_rules" {
  description = "Enable gaming-specific security group rules"
  type        = bool
  default     = true
}

variable "gaming_traffic_cidrs" {
  description = "CIDR blocks allowed for gaming traffic"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "enable_websocket_traffic" {
  description = "Enable WebSocket traffic for real-time gaming"
  type        = bool
  default     = true
}

# ==============================================================================
# CONTAINER INSIGHTS AND MONITORING
# ==============================================================================

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

# ==============================================================================
# FARGATE CONFIGURATION
# ==============================================================================

variable "enable_fargate_profiles" {
  description = "Enable Fargate profiles for serverless gaming workloads"
  type        = bool
  default     = false
}

variable "fargate_pod_execution_role_arn" {
  description = "ARN of the pod execution role for Fargate profiles"
  type        = string
  default     = ""
}

# ==============================================================================
# GAMING NAMESPACE AND SERVICE ACCOUNTS
# ==============================================================================

variable "create_gaming_namespace" {
  description = "Create gaming namespace"
  type        = bool
  default     = true
}

variable "create_gaming_service_account" {
  description = "Create gaming service account"
  type        = bool
  default     = true
}

variable "gaming_workload_role_arn" {
  description = "ARN of the IAM role for gaming workloads"
  type        = string
  default     = ""
}

# ==============================================================================
# CLUSTER AUTOSCALER
# ==============================================================================

variable "enable_cluster_autoscaler" {
  description = "Enable cluster autoscaler service account"
  type        = bool
  default     = true
}

variable "cluster_autoscaler_role_arn" {
  description = "ARN of the IAM role for cluster autoscaler"
  type        = string
  default     = ""
}

# ==============================================================================
# ENVIRONMENT-SPECIFIC CONFIGURATIONS
# ==============================================================================

variable "environment_config" {
  description = "Environment-specific configurations"
  type = object({
    enable_spot_instances    = optional(bool, false)
    enable_gpu_nodes        = optional(bool, false)
    enable_arm_nodes        = optional(bool, false)
    max_pods_per_node       = optional(number, 110)
    enable_network_policies = optional(bool, true)
    enable_pod_security     = optional(bool, true)
  })
  default = {
    enable_spot_instances    = false
    enable_gpu_nodes        = false
    enable_arm_nodes        = false
    max_pods_per_node       = 110
    enable_network_policies = true
    enable_pod_security     = true
  }
}

# ==============================================================================
# ADDON CONFIGURATION OVERRIDES
# ==============================================================================

variable "addon_configurations" {
  description = "Custom configurations for EKS addons"
  type = object({
    vpc_cni_custom_config      = optional(map(any), {})
    coredns_custom_config      = optional(map(any), {})
    kube_proxy_custom_config   = optional(map(any), {})
    ebs_csi_custom_config      = optional(map(any), {})
    efs_csi_custom_config      = optional(map(any), {})
  })
  default = {
    vpc_cni_custom_config    = {}
    coredns_custom_config    = {}
    kube_proxy_custom_config = {}
    ebs_csi_custom_config    = {}
    efs_csi_custom_config    = {}
  }
}
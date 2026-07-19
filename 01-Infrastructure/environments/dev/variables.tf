# ==============================================================================
# DEV ENVIRONMENT - VARIABLES
# ==============================================================================
# Description: Variable definitions for development environment
# Environment: Development
# Author: Platform Engineering Team
# Version: 1.0.0
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
  default     = "engineering"
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
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

# ==============================================================================
# EKS CLUSTER VARIABLES
# ==============================================================================

variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
  
  validation {
    condition = contains([
      "1.26", "1.27", "1.28", "1.29"
    ], var.eks_cluster_version)
    error_message = "EKS cluster version must be a supported version."
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
  
  default = {
    # Public Node Group - Web servers, Load Balancers, Bastion
    public_web = {
      node_group_name = "public-web-nodes"
      subnet_type     = "public"
      
      instance_types = ["t3.medium", "t3a.medium"]
      ami_type      = "AL2_x86_64"
      capacity_type = "SPOT"  # Cost optimization for dev
      
      min_size         = 1
      max_size         = 3
      desired_capacity = 2
      
      disk_size      = 50
      disk_type      = "gp3"
      disk_encrypted = true
      
      remote_access = {
        ec2_ssh_key               = "dev-eks-nodes"
        source_security_group_ids = []
      }
      
      taints = [{
        key    = "node-type"
        value  = "web"
        effect = "NO_SCHEDULE"
      }]
      
      labels = {
        "node-type"    = "web"
        "network-zone" = "public"
        "workload"     = "frontend"
      }
      
      update_config = {
        max_unavailable_percentage = 25
      }
      
      enable_monitoring  = true
      kubernetes_version = "1.28"
    },
    
    # Private Node Group - Application servers
    private_app = {
      node_group_name = "private-app-nodes"
      subnet_type     = "private"
      
      instance_types = ["t3.large", "t3a.large"]
      ami_type      = "AL2_x86_64"
      capacity_type = "ON_DEMAND"
      
      min_size         = 1
      max_size         = 5
      desired_capacity = 2
      
      disk_size      = 100
      disk_type      = "gp3"
      disk_encrypted = true
      
      remote_access = {
        ec2_ssh_key               = "dev-eks-nodes"
        source_security_group_ids = []
      }
      
      taints = [{
        key    = "node-type"
        value  = "application"
        effect = "NO_SCHEDULE"
      }]
      
      labels = {
        "node-type"    = "application"
        "network-zone" = "private"
        "workload"     = "backend"
      }
      
      update_config = {
        max_unavailable_percentage = 25
      }
      
      enable_monitoring  = true
      kubernetes_version = "1.28"
    },
    
    # Database Node Group - Database workloads only
    database_nodes = {
      node_group_name = "database-nodes"
      subnet_type     = "database"
      
      instance_types = ["r5.large", "r5a.large"]
      ami_type      = "AL2_x86_64"
      capacity_type = "ON_DEMAND"
      
      min_size         = 1
      max_size         = 3
      desired_capacity = 1
      
      disk_size      = 200
      disk_type      = "io1"
      disk_encrypted = true
      
      remote_access = {
        ec2_ssh_key               = "dev-eks-nodes"
        source_security_group_ids = []
      }
      
      taints = [{
        key    = "node-type"
        value  = "database"
        effect = "NO_SCHEDULE"
      }]
      
      labels = {
        "node-type"    = "database"
        "network-zone" = "database"
        "workload"     = "database"
      }
      
      update_config = {
        max_unavailable_percentage = 0  # Conservative for database
      }
      
      enable_monitoring  = true
      kubernetes_version = "1.28"
    }
  }
}

# ==============================================================================
# SECURITY VARIABLES
# ==============================================================================

variable "kms_key_administrators" {
  description = "List of IAM user/role ARNs that can administer KMS keys"
  type        = list(string)
  default     = []
}

variable "kms_key_users" {
  description = "List of IAM user/role ARNs that can use KMS keys"
  type        = list(string)
  default     = []
}

variable "aws_auth_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "aws_auth_users" {
  description = "Additional IAM users to add to the aws-auth configmap"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

# ==============================================================================
# BASTION HOST VARIABLES
# ==============================================================================

variable "create_bastion_host" {
  description = "Whether to create a bastion host"
  type        = bool
  default     = true
}

variable "bastion_instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t3.micro"
}

variable "bastion_key_name" {
  description = "Key pair name for bastion host"
  type        = string
  default     = "dev-bastion"
}

# ==============================================================================
# MONITORING AND LOGGING
# ==============================================================================

variable "enable_cloudwatch_logging" {
  description = "Enable CloudWatch logging for EKS"
  type        = bool
  default     = false  # Disabled in dev for cost optimization
}

variable "enable_container_insights" {
  description = "Enable Container Insights for EKS"
  type        = bool
  default     = false  # Disabled in dev for cost optimization
}
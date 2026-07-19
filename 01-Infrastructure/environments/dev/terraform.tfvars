# ==============================================================================
# DEV ENVIRONMENT - TERRAFORM VARIABLES
# ==============================================================================
# Description: Variable values for development environment
# Environment: Development
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

# ==============================================================================
# PROJECT CONFIGURATION
# ==============================================================================
project_name   = "tetris-platform"
aws_region     = "us-east-1"
owner          = "platform-engineering-team"
cost_center    = "engineering-dev"
business_unit  = "platform"

# ==============================================================================
# NETWORKING CONFIGURATION
# ==============================================================================
vpc_cidr = "10.10.0.0/16"  # Dev environment VPC

# ==============================================================================
# EKS CLUSTER CONFIGURATION
# ==============================================================================
eks_cluster_version = "1.28"

# ==============================================================================
# NODE GROUP CONFIGURATIONS (DEV-OPTIMIZED)
# ==============================================================================
node_group_configs = {
  # Public Node Group - Web servers, Load Balancers, Bastion (Cost-optimized)
  public_web = {
    node_group_name = "dev-public-web-nodes"
    subnet_type     = "public"
    
    instance_types = ["t3.small", "t3a.small"]  # Smaller instances for dev
    ami_type      = "AL2_x86_64"
    capacity_type = "SPOT"  # Cost optimization
    
    min_size         = 0  # Allow scaling to zero in dev
    max_size         = 2  # Limited scale for dev
    desired_capacity = 1  # Single node for dev
    
    disk_size      = 30   # Smaller disk for dev
    disk_type      = "gp3"
    disk_encrypted = false  # Cost optimization for dev
    
    remote_access = {
      ec2_ssh_key               = "dev-eks-nodes"
      source_security_group_ids = []
    }
    
    taints = []  # No taints in dev for flexibility
    
    labels = {
      "node-type"    = "web"
      "network-zone" = "public"
      "workload"     = "frontend"
      "environment"  = "dev"
      "cost-optimization" = "enabled"
    }
    
    update_config = {
      max_unavailable_percentage = 50  # Faster updates in dev
    }
    
    enable_monitoring  = false  # Cost optimization
    kubernetes_version = "1.28"
  },
  
  # Private Node Group - Application servers (Multi-purpose in dev)
  private_app = {
    node_group_name = "dev-private-app-nodes"
    subnet_type     = "private"
    
    instance_types = ["t3.medium", "t3a.medium"]
    ami_type      = "AL2_x86_64"
    capacity_type = "SPOT"  # Cost optimization
    
    min_size         = 1
    max_size         = 3
    desired_capacity = 1  # Single node for dev
    
    disk_size      = 50   # Moderate disk for dev
    disk_type      = "gp3"
    disk_encrypted = false  # Cost optimization
    
    remote_access = {
      ec2_ssh_key               = "dev-eks-nodes"
      source_security_group_ids = []
    }
    
    taints = []  # No taints in dev for flexibility
    
    labels = {
      "node-type"    = "application"
      "network-zone" = "private"
      "workload"     = "backend"
      "environment"  = "dev"
      "cost-optimization" = "enabled"
    }
    
    update_config = {
      max_unavailable_percentage = 50  # Faster updates in dev
    }
    
    enable_monitoring  = false  # Cost optimization
    kubernetes_version = "1.28"
  }
}

# ==============================================================================
# SECURITY CONFIGURATION (DEV-FRIENDLY)
# ==============================================================================
kms_key_administrators = [
  "arn:aws:iam::ACCOUNT_ID:root"  # Replace with actual account ID
]

kms_key_users = [
  "arn:aws:iam::ACCOUNT_ID:root"  # Replace with actual account ID
]

aws_auth_roles = [
  {
    rolearn  = "arn:aws:iam::ACCOUNT_ID:role/DevOpsTeam"
    username = "devops-team"
    groups   = ["system:masters"]
  },
  {
    rolearn  = "arn:aws:iam::ACCOUNT_ID:role/DevelopersTeam"
    username = "developers-team"
    groups   = ["system:masters"]  # Full access in dev
  }
]

aws_auth_users = [
  {
    userarn  = "arn:aws:iam::ACCOUNT_ID:user/platform-engineer"
    username = "platform-engineer"
    groups   = ["system:masters"]
  }
]

# ==============================================================================
# BASTION HOST CONFIGURATION
# ==============================================================================
create_bastion_host    = true
bastion_instance_type  = "t3.micro"  # Cost-optimized
bastion_key_name      = "dev-bastion-key"

# ==============================================================================
# MONITORING AND LOGGING (COST-OPTIMIZED FOR DEV)
# ==============================================================================
enable_cloudwatch_logging = false  # Disabled for cost optimization
enable_container_insights = false   # Disabled for cost optimization
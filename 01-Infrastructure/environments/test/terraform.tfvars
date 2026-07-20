# ==============================================================================
# TEST ENVIRONMENT - TERRAFORM VARIABLES
# ==============================================================================
# Description: Variable values for test environment
# Environment: Test (Production-like but smaller scale, automated testing friendly)
# Author: Platform Engineering Team
# Version: 2.0.0 - Fixed to match working dev structure
# ==============================================================================

# ==============================================================================
# PROJECT CONFIGURATION
# ==============================================================================
project_name   = "tetris-platform"
aws_region     = "us-east-1"
owner          = "platform-engineering-team"
cost_center    = "engineering-test"
business_unit  = "platform"

# ==============================================================================
# NETWORKING CONFIGURATION
# ==============================================================================
vpc_cidr = "10.20.0.0/16"  # Test environment VPC - separate from dev/prod

# Network access configuration (test-friendly but more restricted than dev)
authorized_networks = [
  "10.20.0.0/16",    # VPC CIDR
  "203.0.113.0/24",  # Office network (replace with actual)
  "198.51.100.0/24"  # CI/CD network (replace with actual)
]

allowed_cidrs = [
  "0.0.0.0/0"  # Open for testing - restrict based on requirements
]

office_network_cidrs = [
  "203.0.113.0/24",   # Replace with actual office networks
  "198.51.100.0/24"   # Replace with actual VPN/office networks
]

gaming_traffic_cidrs = [
  "10.0.0.0/8",
  "172.16.0.0/12",
  "192.168.0.0/16"
]

# ==============================================================================
# EKS CLUSTER CONFIGURATION
# ==============================================================================
eks_cluster_version = "1.33"

# ==============================================================================
# NODE GROUP CONFIGURATIONS (TEST ENVIRONMENT - PRODUCTION-LIKE)
# ==============================================================================
node_group_configs = {
  # Test gaming nodes - Production-like for validation
  test_gaming_nodes = {
    node_group_name = "test-gaming-nodes"
    subnet_type     = "private"
    
    instance_types = ["t3.large", "t3a.large"]
    ami_type      = "AL2023_x86_64_STANDARD"  # Modern Amazon Linux for testing
    capacity_type = "ON_DEMAND"  # Stable for testing
    
    min_size         = 2
    max_size         = 10
    desired_capacity = 3
    
    disk_size      = 100
    disk_type      = "gp3"
    disk_encrypted = true
    
    remote_access = {
      ec2_ssh_key               = ""  # No SSH access - use AWS Systems Manager
      source_security_group_ids = []
    }
    
    taints = []  # No taints for testing flexibility
    
    labels = {
      "node-type"    = "gaming"
      "network-zone" = "private"
      "workload"     = "gaming-test"
      "environment"  = "test"
    }
    
    update_config = {
      max_unavailable_percentage = 25  # Production-like
    }
    
    enable_monitoring  = true
    kubernetes_version = "1.33"
  }
}

# ==============================================================================
# ACCESS CONTROL CONFIGURATION
# ==============================================================================
platform_team_access = [
  {
    principal_arn     = "arn:aws:iam::ACCOUNT_ID:role/PlatformTeamRole"  # Replace ACCOUNT_ID
    kubernetes_groups = ["system:masters"]
    type             = "STANDARD"
  }
]

gaming_dev_team_access = [
  {
    principal_arn     = "arn:aws:iam::ACCOUNT_ID:role/GamingDevTeamRole"  # Replace ACCOUNT_ID
    kubernetes_groups = ["gaming:developers", "system:authenticated"]
    type             = "STANDARD"
  }
]

# ==============================================================================
# SECURITY CONFIGURATION
# ==============================================================================
enable_remote_access = false  # No SSH access - use AWS Systems Manager
key_pair_name       = ""     # No key pair needed
create_bastion_host = false  # No bastion needed with proper monitoring

# Encryption settings (production-like for testing)
enable_multi_region = false
require_mfa        = false  # Disabled for automated testing
external_id        = null

# ==============================================================================
# COMPUTE CONFIGURATION
# ==============================================================================
# Enable spot instances for cost optimization in test
enable_spot_instances = true

# Disable GPU nodes for cost optimization (enable if testing GPU workloads)
enable_gpu_nodes = false

# Enable ARM nodes to test compatibility
enable_arm_nodes = true

# ==============================================================================
# NETWORKING FEATURES
# ==============================================================================
enable_vpn_gateway   = false  # Not needed in test
enable_public_access = true   # Enable for test accessibility

trusted_aws_accounts = []
trusted_role_arns = []
# ==============================================================================
# TEST ENVIRONMENT - TERRAFORM VARIABLES
# ==============================================================================
# Description: Variable values for test environment
# Environment: Test (Production-like but smaller scale, automated testing friendly)
# Author: Platform Engineering Team
# Version: 2.0.0
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

# ==============================================================================
# GAMING-SPECIFIC CONFIGURATION
# ==============================================================================
# These values are used by the gaming applications for testing

# Test environment should mirror production settings for validation
# But with smaller scale and relaxed security for testing convenience

# Gaming performance settings (test values)
gaming_performance = {
  max_concurrent_players    = 1000      # Lower than prod for test
  session_timeout_seconds   = 1800      # 30 minutes for testing
  enable_real_time_metrics = true       # Test metrics collection
  websocket_timeout_seconds = 300       # 5 minutes for testing
}

# Test data settings
test_data = {
  enable_synthetic_load = true          # Generate test load
  player_simulation_count = 100         # Simulate 100 concurrent players
  game_duration_minutes = 15            # 15 minute test games
}

# ==============================================================================
# MONITORING AND TESTING
# ==============================================================================
# Enhanced monitoring for test validation
monitoring = {
  enable_detailed_logging = true
  log_level              = "DEBUG"
  enable_performance_monitoring = true
  enable_load_testing    = true
}

# ==============================================================================
# ENVIRONMENT-SPECIFIC OVERRIDES
# ==============================================================================
# Test environment specific configurations that differ from defaults

environment_overrides = {
  # Network settings
  single_nat_gateway = false  # Multi-AZ for production-like testing
  
  # Security settings
  flow_logs_retention_days = 14  # Extended retention for test analysis
  
  # Compute settings
  node_group_min_size = 2   # Minimum for HA testing
  node_group_max_size = 10  # Reasonable scale for testing
  
  # Storage settings
  ebs_volume_size = 50      # Moderate size for testing
  
  # Backup settings
  backup_enabled = true     # Test backup functionality
  backup_retention_days = 7 # Short retention for test
}
# ==============================================================================
# PROD ENVIRONMENT - TERRAFORM VARIABLES
# ==============================================================================
# Description: Variable values for production environment
# Environment: Production (Maximum availability, security, performance, disaster recovery)
# Author: Platform Engineering Team
# Version: 2.0.0
# ==============================================================================

# ==============================================================================
# PROJECT CONFIGURATION
# ==============================================================================
project_name   = "tetris-platform"
aws_region     = "us-east-1"  # Production in us-east-1 for optimal latency
owner          = "platform-engineering-team"
cost_center    = "engineering-production"
business_unit  = "platform"

# ==============================================================================
# NETWORKING CONFIGURATION
# ==============================================================================
vpc_cidr = "10.100.0.0/16"  # Production environment VPC

# Network access configuration (RESTRICTED FOR PRODUCTION)
# IMPORTANT: Replace these with actual networks before deployment
authorized_networks = [
  "10.100.0.0/16",    # VPC CIDR
  # "YOUR_OFFICE_NETWORK/24",     # Replace with actual office network
  # "YOUR_VPN_NETWORK/24",        # Replace with actual VPN network
  # "YOUR_CI_CD_NETWORK/24"       # Replace with actual CI/CD network
]

allowed_cidrs = [
  # "0.0.0.0/0"  # DO NOT USE IN PRODUCTION - restrict to specific networks
  # Add specific CIDR blocks for production traffic
  # Example: "203.0.113.0/24"  # Customer access network
]

office_network_cidrs = [
  # "YOUR_OFFICE_CIDR/24",        # Replace with actual office networks
  # "YOUR_ADMIN_VPN_CIDR/24"      # Replace with actual admin VPN
]

gaming_traffic_cidrs = [
  "10.0.0.0/8",      # Private networks
  "172.16.0.0/12",   # Private networks
  "192.168.0.0/16"   # Private networks
]

# ==============================================================================
# EKS CLUSTER CONFIGURATION
# ==============================================================================
eks_cluster_version = "1.33"  # Latest stable for production

# ==============================================================================
# NODE GROUP CONFIGURATIONS (PRODUCTION-OPTIMIZED)
# ==============================================================================
node_group_configs = {
  # Primary gaming nodes - Ultra-high performance
  prod_gaming_primary = {
    node_group_name = "prod-gaming-primary"
    subnet_type     = "private"
    
    instance_types = ["m5.xlarge", "c5.xlarge", "m5.2xlarge"]
    ami_type      = "BOTTLEROCKET_x86_64"  # Maximum gaming performance
    capacity_type = "ON_DEMAND"  # Stability for production
    
    min_size         = 3
    max_size         = 20
    desired_capacity = 5
    
    disk_size      = 200
    disk_type      = "gp3"
    disk_encrypted = true
    
    remote_access = {
      ec2_ssh_key               = ""  # No SSH access in production
      source_security_group_ids = []
    }
    
    taints = [{
      key    = "gaming.io/production"
      value  = "true"
      effect = "NO_SCHEDULE"
    }]
    
    labels = {
      "node-type"    = "gaming-primary"
      "network-zone" = "private"
      "workload"     = "gaming-production"
      "environment"  = "prod"
      "gaming.io/performance" = "ultra"
      "gaming.io/production-ready" = "true"
    }
    
    update_config = {
      max_unavailable_percentage = 10  # Conservative for production
    }
    
    enable_monitoring  = true
    kubernetes_version = "1.33"
  }
  
  # Secondary gaming nodes for overflow and scaling
  prod_gaming_secondary = {
    node_group_name = "prod-gaming-secondary"
    subnet_type     = "private"
    
    instance_types = ["m5.large", "c5.large", "m5.xlarge"]
    ami_type      = "BOTTLEROCKET_x86_64"  # Consistent performance
    capacity_type = "SPOT"  # Cost optimization for overflow
    
    min_size         = 0
    max_size         = 15
    desired_capacity = 2
    
    disk_size      = 100
    disk_type      = "gp3"
    disk_encrypted = true
    
    remote_access = {
      ec2_ssh_key               = ""  # No SSH access
      source_security_group_ids = []
    }
    
    taints = [{
      key    = "gaming.io/burst"
      value  = "true"
      effect = "NO_SCHEDULE"
    }]
    
    labels = {
      "node-type"    = "gaming-secondary"
      "network-zone" = "private"
      "workload"     = "gaming-overflow"
      "environment"  = "prod"
      "gaming.io/performance" = "high"
      "gaming.io/burst-capable" = "true"
    }
    
    update_config = {
      max_unavailable_percentage = 25  # Can handle more disruption
    }
    
    enable_monitoring  = true
    kubernetes_version = "1.33"
  }
}

# ==============================================================================
# ACCESS CONTROL CONFIGURATION (PRODUCTION RESTRICTED)
# ==============================================================================
platform_team_access = [
  {
    # IMPORTANT: Replace ACCOUNT_ID with actual AWS account ID
    principal_arn     = "arn:aws:iam::ACCOUNT_ID:role/ProductionPlatformTeamRole"
    kubernetes_groups = ["system:masters"]
    type             = "STANDARD"
  }
]

# NO DEV TEAM ACCESS IN PRODUCTION
gaming_dev_team_access = []

# ==============================================================================
# SECURITY CONFIGURATION (MAXIMUM SECURITY)
# ==============================================================================
enable_remote_access = false  # Disabled for production security
key_pair_name       = ""      # No SSH access in production
create_bastion_host = false   # Disabled for production security

# Encryption settings (maximum security)
enable_multi_region = false  # Set to true if multi-region DR is required
require_mfa        = true    # Mandatory for production
external_id        = null    # Set if cross-account access is needed

# Trusted accounts for cross-account access (if needed)
trusted_aws_accounts = [
  # "123456789012"  # Add trusted account IDs if needed
]

trusted_role_arns = [
  # "arn:aws:iam::ACCOUNT_ID:role/CrossAccountRole"  # Add trusted roles if needed
]

# ==============================================================================
# COMPUTE CONFIGURATION (PRODUCTION OPTIMIZED)
# ==============================================================================
# Spot instances - disabled by default for production stability
enable_spot_instances = false  # Set to true only if acceptable for your workload

# GPU nodes - optional for advanced gaming features
enable_gpu_nodes = false  # Set to true if GPU acceleration is needed

# ARM nodes - optional for cost optimization
enable_arm_nodes = false  # Set to true if ARM compatibility is validated

# ==============================================================================
# NETWORKING FEATURES
# ==============================================================================
enable_vpn_gateway   = false  # Set to true if site-to-site VPN is needed
enable_public_access = false  # Disabled for maximum security

# ==============================================================================
# HIGH AVAILABILITY AND DISASTER RECOVERY
# ==============================================================================
enable_cross_region_backup = true
backup_retention_days      = 90  # Extended retention for production

enable_monitoring_alerts = true

# ==============================================================================
# COMPLIANCE AND GOVERNANCE
# ==============================================================================
compliance_framework         = "SOC2"  # Adjust based on requirements
enable_audit_logging        = true
data_residency_requirements = "us"

# ==============================================================================
# PERFORMANCE AND SCALING (PRODUCTION GRADE)
# ==============================================================================
performance_tier        = "high"  # High performance for production gaming
auto_scaling_target_cpu = 70      # Conservative scaling threshold

# ==============================================================================
# GAMING-SPECIFIC CONFIGURATION (PRODUCTION VALUES)
# ==============================================================================
# Production gaming platform configuration

gaming_performance = {
  max_concurrent_players    = 50000     # Production scale
  session_timeout_seconds   = 7200      # 2 hours for production
  enable_real_time_metrics = true       # Essential for production monitoring
  websocket_timeout_seconds = 3600      # 1 hour for production
  
  # Production performance settings
  max_connections_per_node = 1000       # High connection density
  enable_session_affinity  = true       # Required for gaming
  enable_low_latency_mode  = true       # Critical for real-time gaming
}

# Production data settings
production_data = {
  enable_data_encryption    = true       # Mandatory for production
  backup_frequency_hours    = 6          # Every 6 hours
  cross_region_replication = true        # For disaster recovery
  data_retention_days      = 2555        # 7 years retention
}

# ==============================================================================
# MONITORING AND ALERTING (PRODUCTION GRADE)
# ==============================================================================
monitoring = {
  enable_detailed_logging      = true
  log_level                   = "INFO"    # Production log level
  enable_performance_monitoring = true
  enable_security_monitoring   = true
  enable_cost_monitoring      = true
  
  # Alert thresholds
  cpu_alert_threshold         = 80        # Alert at 80% CPU
  memory_alert_threshold      = 85        # Alert at 85% memory
  disk_alert_threshold        = 90        # Alert at 90% disk
  
  # Gaming-specific monitoring
  player_connection_alert_threshold = 40000  # Alert at 80% capacity
  latency_alert_threshold_ms       = 100     # Alert if latency > 100ms
  error_rate_alert_threshold       = 1       # Alert if error rate > 1%
}

# ==============================================================================
# SECURITY CONFIGURATION (PRODUCTION HARDENED)
# ==============================================================================
security = {
  enable_network_policies    = true       # Mandatory for production
  enable_pod_security_policies = true     # Mandatory for production
  enable_admission_controllers = true      # Enhanced security
  
  # Network security
  enable_vpc_flow_logs      = true
  enable_security_groups_logging = true
  
  # Access control
  session_timeout_minutes   = 60          # 1 hour session timeout
  enable_audit_logging     = true
  
  # Gaming-specific security
  enable_anti_cheat_monitoring = true
  enable_ddos_protection      = true
  rate_limiting_enabled       = true
}

# ==============================================================================
# ENVIRONMENT-SPECIFIC OVERRIDES (PRODUCTION OPTIMIZED)
# ==============================================================================
environment_overrides = {
  # Network settings (production HA)
  single_nat_gateway = false             # Multi-AZ NAT for HA
  
  # Security settings (maximum)
  flow_logs_retention_days = 90          # Extended retention
  enable_encryption_at_rest = true       # Mandatory
  enable_encryption_in_transit = true    # Mandatory
  
  # Compute settings (production scale)
  node_group_min_size = 3               # Minimum for HA
  node_group_max_size = 20              # Production scale
  node_group_desired_size = 5           # Starting capacity
  
  # Storage settings (production grade)
  ebs_volume_size = 100                 # Larger volumes
  ebs_volume_type = "gp3"               # High performance
  ebs_iops = 4000                       # High IOPS
  
  # Backup settings (production DR)
  backup_enabled = true
  backup_retention_days = 90
  cross_region_backup = true
  
  # Monitoring settings (comprehensive)
  detailed_monitoring_enabled = true
  container_insights_enabled = true
  performance_insights_enabled = true
}

# ==============================================================================
# COST OPTIMIZATION (PRODUCTION BALANCED)
# ==============================================================================
cost_optimization = {
  enable_spot_instances_for_batch = false  # Disabled for critical workloads
  reserved_instance_coverage = 80          # 80% reserved instances
  enable_auto_scaling = true               # Efficient scaling
  
  # Schedule-based scaling (adjust based on gaming patterns)
  scaling_schedule = {
    scale_up_time   = "18:00"             # Scale up for evening gaming
    scale_down_time = "06:00"             # Scale down for low traffic
    weekend_scaling = "enabled"            # Higher capacity on weekends
  }
}
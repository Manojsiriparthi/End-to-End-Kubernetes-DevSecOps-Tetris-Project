# ==============================================================================
# DEV ENVIRONMENT - EKS ADDONS CONFIGURATION
# ==============================================================================
# Description: Development environment addon configuration for gaming platform
# Environment: Development
# Gaming Focus: Cost-optimized, developer-friendly, testing-enabled
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

# ==============================================================================
# CORE CONFIGURATION
# ==============================================================================
project_name = "tetris-platform"
environment  = "dev"
aws_region   = "us-west-2"

# Infrastructure state location
infrastructure_state_bucket = "tetris-platform-terraform-state-dev"
infrastructure_state_key    = "infrastructure/dev/terraform.tfstate"

# ==============================================================================
# GAMING CONFIGURATION (DEV-OPTIMIZED)
# ==============================================================================
gaming_dns_zones = [
  "dev-game.tetris-platform.com",
  "dev-api.tetris-platform.com"
]

gaming_application_config = {
  max_concurrent_players     = 500     # Limited for dev
  websocket_timeout_seconds  = 300     # 5 minutes
  session_affinity_duration  = 1800    # 30 minutes (shorter for dev)
  real_time_metrics_interval = 30      # 30 seconds (less frequent)
  game_session_timeout       = 900     # 15 minutes (shorter for dev)
  auto_scaling_target_cpu    = 80      # Higher threshold for cost savings
  auto_scaling_target_memory = 85      # Higher threshold for cost savings
}

# ==============================================================================
# LOAD BALANCER CONFIGURATION (DEV)
# ==============================================================================
aws_load_balancer_controller_config = {
  replica_count              = 1       # Single replica for cost
  enable_waf_v2             = false    # Disabled for cost
  enable_shield_advanced    = false    # Disabled for cost
  enable_websocket_support  = true     # Keep gaming features
  enable_session_affinity   = true     # Keep gaming features
  ingress_class_name        = "alb"
  default_ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

# ==============================================================================
# GATEWAY API CONFIGURATION (DEV)
# ==============================================================================
gateway_api_config = {
  gateway_class_name         = "gaming-gateway-dev"
  enable_rate_limiting       = true     # Keep for testing
  enable_circuit_breaker     = true     # Keep for testing
  enable_websocket_routing   = true     # Gaming requirement
  enable_real_time_metrics   = false    # Disabled for cost
  default_timeout_seconds    = 30
  max_requests_per_second    = 100      # Lower limit for dev
}

# ==============================================================================
# KARPENTER CONFIGURATION (DEV)
# ==============================================================================
karpenter_config = {
  max_nodes_per_nodepool     = 5       # Limited for dev
  instance_families          = ["t3", "t3a", "m5", "m5a"]  # Include burstable instances
  instance_sizes            = ["medium", "large", "xlarge"] # Smaller sizes
  cpu_architecture          = ["amd64"]
  capacity_types            = ["spot"]  # Spot only for maximum cost savings
  enable_spot_instances     = true
  spot_max_price_percentage = 50       # Aggressive spot pricing for dev
}

# ==============================================================================
# AUTO-SCALING CONFIGURATION (DEV)
# ==============================================================================
horizontal_pod_autoscaler_config = {
  max_replicas                    = 5   # Limited scaling for dev
  min_replicas                    = 1
  target_cpu_utilization         = 80   # Higher threshold for cost
  target_memory_utilization      = 85   # Higher threshold for cost
  scale_up_stabilization_seconds  = 120 # Slower scaling for cost
  scale_down_stabilization_seconds = 600 # Conservative scale-down
  
  # Gaming-specific metrics (reduced for dev)
  active_connections_per_pod      = 200  # Lower capacity per pod
  active_game_sessions_per_pod    = 100  # Lower sessions per pod
  websocket_connections_per_pod   = 150  # Lower WebSocket capacity
  response_time_threshold_ms      = 200  # More relaxed latency
}

vertical_pod_autoscaler_config = {
  enable_gaming_recommendations = true
  enable_real_time_updates     = false   # Disabled for stability in dev
  update_mode                  = "Off"    # Recommendations only in dev
  
  # Reduced resource limits for dev
  game_server_min_cpu         = "50m"
  game_server_max_cpu         = "500m"    # Smaller max for dev
  game_server_min_memory      = "64Mi"
  game_server_max_memory      = "1Gi"     # Smaller max for dev
  
  websocket_handler_min_cpu   = "25m"
  websocket_handler_max_cpu   = "250m"    # Smaller max for dev
  websocket_handler_min_memory = "32Mi"
  websocket_handler_max_memory = "512Mi"  # Smaller max for dev
}

# ==============================================================================
# METRICS AND MONITORING (DEV)
# ==============================================================================
metrics_server_config = {
  enable_high_frequency_metrics = false  # Cost optimization
  metrics_resolution_seconds    = 30     # Lower frequency
  enable_network_metrics        = true   # Keep for gaming
  enable_websocket_metrics      = true   # Keep for gaming
  enable_session_metrics        = false  # Disabled for cost
  enable_latency_metrics        = true   # Keep for gaming
}

cloudwatch_config = {
  log_retention_days          = 7       # Short retention for cost
  enable_gaming_metrics       = true    # Keep essential gaming metrics
  enable_performance_insights = false   # Disabled for cost
  enable_custom_dashboards    = true    # Keep for development
  
  # Gaming dashboards (selective for dev)
  enable_player_metrics_dashboard    = true   # Useful for dev
  enable_game_performance_dashboard  = true   # Useful for dev
  enable_websocket_monitoring_dashboard = false # Disabled for cost
  enable_session_analytics_dashboard = false   # Disabled for cost
}

# ==============================================================================
# STORAGE CONFIGURATION (DEV)
# ==============================================================================
ebs_csi_config = {
  enable_gp3_by_default        = true
  enable_fast_snapshot_restore = false   # Cost optimization
  enable_volume_encryption     = false   # Disabled for cost in dev
  
  # Reduced storage performance for dev
  game_data_iops              = 3000     # Lower IOPS
  game_data_throughput        = 250      # Lower throughput
  session_state_iops          = 6000     # Lower IOPS
  session_state_type          = "gp3"    # Use gp3 instead of io2 for cost
}

efs_csi_config = {
  performance_mode = "generalPurpose"     # Standard performance for dev
  throughput_mode  = "bursting"           # Bursting for cost
  encrypted        = false                # Disabled for cost in dev
  provisioned_throughput_in_mibps = 100   # Lower throughput
}

# ==============================================================================
# NETWORK AND DNS CONFIGURATION (DEV)
# ==============================================================================
external_dns_config = {
  txt_owner_id     = "tetris-platform-dev-external-dns"
  policy          = "sync"        # More aggressive for dev testing
  registry        = "txt"
  interval        = "5m"          # Less frequent updates
}

# ==============================================================================
# SECURITY CONFIGURATION (DEV - RELAXED)
# ==============================================================================
security_config = {
  enable_pod_security_standards = false  # Relaxed for development
  enable_network_policies       = false  # Relaxed for development
  enable_service_mesh          = false   # Not needed in dev
  default_security_context = {
    run_as_non_root        = false       # Relaxed for dev convenience
    read_only_root_filesystem = false    # Relaxed for dev convenience
    allow_privilege_escalation = true    # Relaxed for dev debugging
  }
}

# ==============================================================================
# FALLBACK CONFIGURATION
# ==============================================================================
enable_cluster_autoscaler_fallback = false   # Use Karpenter only

# ==============================================================================
# DEV ENVIRONMENT NOTES
# ==============================================================================
# 1. Cost Optimization: Aggressive use of spot instances, reduced monitoring
# 2. Developer Friendly: Relaxed security, easier debugging capabilities
# 3. Gaming Features: Core gaming features preserved for testing
# 4. Limited Scale: Reduced capacity for cost control
# 5. Shorter Retention: Logs and metrics retained for shorter periods
# 6. Single Replicas: Most services run single replica for cost
# ==============================================================================
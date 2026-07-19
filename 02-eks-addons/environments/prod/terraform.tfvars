# ==============================================================================
# PRODUCTION ENVIRONMENT - EKS ADDONS CONFIGURATION
# ==============================================================================
# Description: Production environment addon configuration for gaming platform
# Environment: Production
# Gaming Focus: Maximum performance, reliability, security, scalability
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

# ==============================================================================
# CORE CONFIGURATION
# ==============================================================================
project_name = "tetris-platform"
environment  = "prod"
aws_region   = "us-west-2"

# Infrastructure state location
infrastructure_state_bucket = "tetris-platform-terraform-state-prod"
infrastructure_state_key    = "infrastructure/prod/terraform.tfstate"

# ==============================================================================
# GAMING CONFIGURATION (PRODUCTION-OPTIMIZED)
# ==============================================================================
gaming_dns_zones = [
  "game.tetris-platform.com",
  "api.tetris-platform.com",
  "ws.tetris-platform.com",      # Dedicated WebSocket domain
  "cdn.tetris-platform.com"      # CDN domain for assets
]

gaming_application_config = {
  max_concurrent_players     = 50000    # Production scale
  websocket_timeout_seconds  = 600      # 10 minutes
  session_affinity_duration  = 7200     # 2 hours
  real_time_metrics_interval = 5        # 5 seconds (high frequency)
  game_session_timeout       = 3600     # 1 hour
  auto_scaling_target_cpu    = 60       # Conservative for performance
  auto_scaling_target_memory = 70       # Conservative for performance
}

# ==============================================================================
# LOAD BALANCER CONFIGURATION (PRODUCTION)
# ==============================================================================
aws_load_balancer_controller_config = {
  replica_count              = 3        # High availability
  enable_waf_v2             = true      # Security for production
  enable_shield_advanced    = true      # DDoS protection
  enable_websocket_support  = true      # Gaming requirement
  enable_session_affinity   = true      # Gaming requirement
  ingress_class_name        = "alb"
  default_ssl_policy        = "ELBSecurityPolicy-TLS-1-3-2021-06"  # Latest TLS
}

# ==============================================================================
# GATEWAY API CONFIGURATION (PRODUCTION)
# ==============================================================================
gateway_api_config = {
  gateway_class_name         = "gaming-gateway-prod"
  enable_rate_limiting       = true      # Essential for production
  enable_circuit_breaker     = true      # Fault tolerance
  enable_websocket_routing   = true      # Gaming requirement
  enable_real_time_metrics   = true      # Full monitoring
  default_timeout_seconds    = 60       # More generous for production
  max_requests_per_second    = 10000     # High capacity
}

# ==============================================================================
# KARPENTER CONFIGURATION (PRODUCTION)
# ==============================================================================
karpenter_config = {
  max_nodes_per_nodepool     = 100      # Large scale capacity
  instance_families          = ["m5", "m5n", "c5", "c5n", "r5", "r5n", "m6i", "c6i", "r6i"]
  instance_sizes            = ["large", "xlarge", "2xlarge", "4xlarge", "8xlarge"]
  cpu_architecture          = ["amd64"]
  capacity_types            = ["on-demand", "spot"]  # Mixed for cost optimization
  enable_spot_instances     = true
  spot_max_price_percentage = 70        # Conservative spot pricing
}

# ==============================================================================
# AUTO-SCALING CONFIGURATION (PRODUCTION)
# ==============================================================================
horizontal_pod_autoscaler_config = {
  max_replicas                    = 50   # High scale capacity
  min_replicas                    = 3    # Always have minimum availability
  target_cpu_utilization         = 60    # Conservative for performance
  target_memory_utilization      = 70    # Conservative for performance
  scale_up_stabilization_seconds  = 30   # Fast scaling for player spikes
  scale_down_stabilization_seconds = 300 # Conservative scale-down
  
  # Gaming-specific metrics (production scale)
  active_connections_per_pod      = 1000 # High capacity per pod
  active_game_sessions_per_pod    = 500  # Balanced load per pod
  websocket_connections_per_pod   = 800  # High WebSocket capacity
  response_time_threshold_ms      = 50   # Strict latency requirements
}

vertical_pod_autoscaler_config = {
  enable_gaming_recommendations = true
  enable_real_time_updates     = true    # Real-time optimization
  update_mode                  = "Recreation"  # Safe updates in production
  
  # Production resource limits
  game_server_min_cpu         = "200m"
  game_server_max_cpu         = "4000m"   # High performance
  game_server_min_memory      = "256Mi"
  game_server_max_memory      = "8Gi"     # High memory for game state
  
  websocket_handler_min_cpu   = "100m"
  websocket_handler_max_cpu   = "2000m"   # High performance
  websocket_handler_min_memory = "128Mi"
  websocket_handler_max_memory = "4Gi"    # High memory for connections
}

# ==============================================================================
# METRICS AND MONITORING (PRODUCTION)
# ==============================================================================
metrics_server_config = {
  enable_high_frequency_metrics = true   # Full monitoring
  metrics_resolution_seconds    = 10     # High frequency
  enable_network_metrics        = true   # Full network monitoring
  enable_websocket_metrics      = true   # Gaming requirement
  enable_session_metrics        = true   # Full session tracking
  enable_latency_metrics        = true   # Performance monitoring
}

cloudwatch_config = {
  log_retention_days          = 90      # Long retention for compliance
  enable_gaming_metrics       = true    # Full gaming analytics
  enable_performance_insights = true    # Performance optimization
  enable_custom_dashboards    = true    # Complete monitoring
  
  # All gaming dashboards enabled
  enable_player_metrics_dashboard    = true
  enable_game_performance_dashboard  = true
  enable_websocket_monitoring_dashboard = true
  enable_session_analytics_dashboard = true
}

# ==============================================================================
# STORAGE CONFIGURATION (PRODUCTION)
# ==============================================================================
ebs_csi_config = {
  enable_gp3_by_default        = true
  enable_fast_snapshot_restore = true    # Fast recovery
  enable_volume_encryption     = true    # Security requirement
  
  # High-performance storage for gaming
  game_data_iops              = 16000    # High IOPS for performance
  game_data_throughput        = 1000     # High throughput
  session_state_iops          = 32000    # Ultra-high IOPS for session data
  session_state_type          = "io2"    # Premium storage
}

efs_csi_config = {
  performance_mode = "maxIO"              # Maximum performance
  throughput_mode  = "provisioned"        # Guaranteed performance
  encrypted        = true                 # Security requirement
  provisioned_throughput_in_mibps = 1000  # High throughput for assets
}

# ==============================================================================
# NETWORK AND DNS CONFIGURATION (PRODUCTION)
# ==============================================================================
external_dns_config = {
  txt_owner_id     = "tetris-platform-prod-external-dns"
  policy          = "upsert-only"   # Conservative for production
  registry        = "txt"
  interval        = "1m"            # Frequent updates for availability
}

# ==============================================================================
# SECURITY CONFIGURATION (PRODUCTION)
# ==============================================================================
security_config = {
  enable_pod_security_standards = true   # Full security compliance
  enable_network_policies       = true   # Network security
  enable_service_mesh          = true    # Advanced security and observability
  default_security_context = {
    run_as_non_root        = true        # Security best practice
    read_only_root_filesystem = true     # Immutable containers
    allow_privilege_escalation = false   # Security hardening
  }
}

# ==============================================================================
# FALLBACK CONFIGURATION
# ==============================================================================
enable_cluster_autoscaler_fallback = true   # Production redundancy

cluster_autoscaler_config = {
  scale_down_delay_after_add       = "1m"   # Fast scale-up for production
  scale_down_unneeded_time         = "10m"  # Conservative scale-down
  scale_down_utilization_threshold = 0.5    # Conservative threshold
  skip_nodes_with_local_storage   = true    # Data protection
  skip_nodes_with_system_pods     = true    # System stability
}

# ==============================================================================
# PRODUCTION ENVIRONMENT NOTES
# ==============================================================================
# 1. Maximum Performance: High-performance instances, storage, networking
# 2. High Availability: Multi-replica, cross-AZ deployment, redundancy
# 3. Security Hardened: Full encryption, security policies, compliance
# 4. Comprehensive Monitoring: All metrics, dashboards, alerting enabled
# 5. Scalability: Large-scale capacity for 50K+ concurrent players
# 6. Disaster Recovery: Fast snapshot restore, backup strategies
# 7. Cost Optimization: Mixed instance types, intelligent spot usage
# 8. Gaming Optimized: Low latency, WebSocket support, session affinity
# ==============================================================================
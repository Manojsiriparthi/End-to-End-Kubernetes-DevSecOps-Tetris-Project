# ==============================================================================
# SECURITY GROUPS MODULE - MAIN CONFIGURATION
# ==============================================================================
# Description: Comprehensive security groups for gaming infrastructure
# Features: Gaming-optimized rules, WebSocket support, real-time traffic optimization
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ==============================================================================
# LOCAL VALUES
# ==============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = merge(var.tags, {
    Component = "security"
    Module    = "security-groups"
  })

  # Gaming-specific port ranges
  gaming_ports = {
    websocket_base    = 8080
    websocket_range   = 10    # 8080-8090
    game_api_port     = 3000
    metrics_port      = 9090
    health_check_port = 8081
    admin_port        = 9000
  }

  # Common CIDR blocks
  common_cidrs = {
    vpc            = var.vpc_cidr_block
    private_subnets = var.private_subnet_cidrs
    public_subnets  = var.public_subnet_cidrs
    office_networks = var.office_network_cidrs
  }
}

# ==============================================================================
# EKS CLUSTER SECURITY GROUP
# ==============================================================================

resource "aws_security_group" "eks_cluster" {
  name        = "${local.name_prefix}-eks-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-eks-cluster-sg"
    Type = "eks-cluster"
    "kubernetes.io/cluster/${local.name_prefix}" = "owned"
  })
}

# HTTPS API server access from authorized networks
resource "aws_security_group_rule" "cluster_api_server_https" {
  count = length(var.authorized_networks) > 0 ? 1 : 0
  
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.authorized_networks
  security_group_id = aws_security_group.eks_cluster.id
  description       = "HTTPS API server access from authorized networks"
}

# Node group communication
resource "aws_security_group_rule" "cluster_node_ingress" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes.id
  security_group_id        = aws_security_group.eks_cluster.id
  description              = "Allow communication from worker nodes"
}

# ==============================================================================
# EKS NODE GROUP SECURITY GROUP
# ==============================================================================

resource "aws_security_group" "eks_nodes" {
  name        = "${local.name_prefix}-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-eks-nodes-sg"
    Type = "eks-nodes"
    "kubernetes.io/cluster/${local.name_prefix}" = "owned"
  })
}

# Self-referencing rule for node-to-node communication
resource "aws_security_group_rule" "nodes_internal" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.eks_nodes.id
  security_group_id        = aws_security_group.eks_nodes.id
  description              = "Allow nodes to communicate with each other"
}

# Cluster to nodes communication
resource "aws_security_group_rule" "nodes_cluster_ingress" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster.id
  security_group_id        = aws_security_group.eks_nodes.id
  description              = "Allow cluster control plane to communicate with worker nodes"
}

# HTTPS from cluster
resource "aws_security_group_rule" "nodes_cluster_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster.id
  security_group_id        = aws_security_group.eks_nodes.id
  description              = "Allow HTTPS from cluster control plane"
}

# ==============================================================================
# GAMING APPLICATION SECURITY GROUP
# ==============================================================================

resource "aws_security_group" "gaming_app" {
  name        = "${local.name_prefix}-gaming-app-sg"
  description = "Security group for gaming applications (Tetris)"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-gaming-app-sg"
    Type = "gaming-application"
    Purpose = "tetris-game-traffic"
  })
}

# HTTP traffic for game web interface
resource "aws_security_group_rule" "gaming_app_http" {
  count = var.enable_gaming_traffic ? 1 : 0
  
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.gaming_app.id
  source_security_group_id = aws_security_group.alb.id
  description       = "HTTP traffic from ALB"
}

# HTTPS traffic for game web interface
resource "aws_security_group_rule" "gaming_app_https" {
  count = var.enable_gaming_traffic ? 1 : 0
  
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.gaming_app.id
  source_security_group_id = aws_security_group.alb.id
  description       = "HTTPS traffic from ALB"
}

# Game API port
resource "aws_security_group_rule" "gaming_app_api" {
  count = var.enable_gaming_traffic ? 1 : 0
  
  type              = "ingress"
  from_port         = local.gaming_ports.game_api_port
  to_port           = local.gaming_ports.game_api_port
  protocol          = "tcp"
  security_group_id = aws_security_group.gaming_app.id
  source_security_group_id = aws_security_group.alb.id
  description       = "Game API traffic from ALB"
}

# WebSocket traffic for real-time gaming
resource "aws_security_group_rule" "gaming_app_websocket" {
  count = var.enable_websocket_traffic ? 1 : 0
  
  type              = "ingress"
  from_port         = local.gaming_ports.websocket_base
  to_port           = local.gaming_ports.websocket_base + local.gaming_ports.websocket_range
  protocol          = "tcp"
  security_group_id = aws_security_group.gaming_app.id
  source_security_group_id = aws_security_group.alb.id
  description       = "WebSocket traffic for real-time gaming communication"
}

# Health check port
resource "aws_security_group_rule" "gaming_app_health_check" {
  type              = "ingress"
  from_port         = local.gaming_ports.health_check_port
  to_port           = local.gaming_ports.health_check_port
  protocol          = "tcp"
  security_group_id = aws_security_group.gaming_app.id
  source_security_group_id = aws_security_group.alb.id
  description       = "Health check port for load balancer"
}

# Node group communication
resource "aws_security_group_rule" "gaming_app_nodes" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes.id
  security_group_id        = aws_security_group.gaming_app.id
  description              = "Communication from EKS nodes"
}

# ==============================================================================
# APPLICATION LOAD BALANCER SECURITY GROUP
# ==============================================================================

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-sg"
    Type = "load-balancer"
  })
}

# HTTP from internet
resource "aws_security_group_rule" "alb_http_internet" {
  count = var.enable_public_access ? 1 : 0
  
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidrs
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from allowed networks"
}

# HTTPS from internet
resource "aws_security_group_rule" "alb_https_internet" {
  count = var.enable_public_access ? 1 : 0
  
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidrs
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from allowed networks"
}

# WebSocket ports from internet
resource "aws_security_group_rule" "alb_websocket_internet" {
  count = var.enable_websocket_traffic && var.enable_public_access ? 1 : 0
  
  type              = "ingress"
  from_port         = local.gaming_ports.websocket_base
  to_port           = local.gaming_ports.websocket_base + local.gaming_ports.websocket_range
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidrs
  security_group_id = aws_security_group.alb.id
  description       = "WebSocket ports for real-time gaming from allowed networks"
}

# ==============================================================================
# DATABASE SECURITY GROUP
# ==============================================================================

resource "aws_security_group" "database" {
  count = var.create_database_security_group ? 1 : 0
  
  name        = "${local.name_prefix}-database-sg"
  description = "Security group for gaming databases"
  vpc_id      = var.vpc_id

  # Restrict outbound traffic to necessary services only
  egress {
    description = "HTTPS for AWS services"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-database-sg"
    Type = "database"
  })
}

# MySQL/Aurora access from gaming applications
resource "aws_security_group_rule" "database_mysql" {
  count = var.create_database_security_group ? 1 : 0
  
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gaming_app.id
  security_group_id        = aws_security_group.database[0].id
  description              = "MySQL/Aurora access from gaming applications"
}

# PostgreSQL access from gaming applications
resource "aws_security_group_rule" "database_postgresql" {
  count = var.create_database_security_group && var.enable_postgresql ? 1 : 0
  
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gaming_app.id
  security_group_id        = aws_security_group.database[0].id
  description              = "PostgreSQL access from gaming applications"
}

# ==============================================================================
# REDIS/ELASTICACHE SECURITY GROUP
# ==============================================================================

resource "aws_security_group" "redis" {
  count = var.create_redis_security_group ? 1 : 0
  
  name        = "${local.name_prefix}-redis-sg"
  description = "Security group for Redis/ElastiCache (gaming session cache)"
  vpc_id      = var.vpc_id

  # No outbound rules needed for Redis
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redis-sg"
    Type = "cache"
    Purpose = "gaming-session-cache"
  })
}

# Redis access from gaming applications
resource "aws_security_group_rule" "redis_access" {
  count = var.create_redis_security_group ? 1 : 0
  
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gaming_app.id
  security_group_id        = aws_security_group.redis[0].id
  description              = "Redis access from gaming applications"
}

# Redis Cluster mode access
resource "aws_security_group_rule" "redis_cluster" {
  count = var.create_redis_security_group && var.enable_redis_cluster ? 1 : 0
  
  type                     = "ingress"
  from_port                = 16379
  to_port                  = 16379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gaming_app.id
  security_group_id        = aws_security_group.redis[0].id
  description              = "Redis Cluster mode access from gaming applications"
}

# ==============================================================================
# MONITORING AND OBSERVABILITY SECURITY GROUP
# ==============================================================================

resource "aws_security_group" "monitoring" {
  count = var.create_monitoring_security_group ? 1 : 0
  
  name        = "${local.name_prefix}-monitoring-sg"
  description = "Security group for monitoring and observability tools"
  vpc_id      = var.vpc_id

  # Allow outbound HTTPS for CloudWatch, etc.
  egress {
    description = "HTTPS for AWS services"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-monitoring-sg"
    Type = "monitoring"
  })
}

# Prometheus metrics collection
resource "aws_security_group_rule" "monitoring_prometheus" {
  count = var.create_monitoring_security_group ? 1 : 0
  
  type                     = "ingress"
  from_port                = local.gaming_ports.metrics_port
  to_port                  = local.gaming_ports.metrics_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gaming_app.id
  security_group_id        = aws_security_group.monitoring[0].id
  description              = "Prometheus metrics collection from gaming applications"
}

# Grafana dashboard access
resource "aws_security_group_rule" "monitoring_grafana" {
  count = var.create_monitoring_security_group && length(var.office_network_cidrs) > 0 ? 1 : 0
  
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = var.office_network_cidrs
  security_group_id = aws_security_group.monitoring[0].id
  description       = "Grafana dashboard access from office networks"
}

# ==============================================================================
# BASTION HOST SECURITY GROUP (for debugging and maintenance)
# ==============================================================================

resource "aws_security_group" "bastion" {
  count = var.create_bastion_security_group ? 1 : 0
  
  name        = "${local.name_prefix}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  # Allow outbound HTTPS and SSH
  egress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "SSH to private networks"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-bastion-sg"
    Type = "bastion"
  })
}

# SSH access from office networks only
resource "aws_security_group_rule" "bastion_ssh" {
  count = var.create_bastion_security_group && length(var.office_network_cidrs) > 0 ? 1 : 0
  
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.office_network_cidrs
  security_group_id = aws_security_group.bastion[0].id
  description       = "SSH access from office networks"
}

# ==============================================================================
# ADDITIONAL SECURITY GROUP RULES FOR GAMING OPTIMIZATIONS
# ==============================================================================

# Node group to gaming app communication for service mesh
resource "aws_security_group_rule" "nodes_to_gaming_app" {
  type                     = "ingress"
  from_port                = 15000
  to_port                  = 15010
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes.id
  security_group_id        = aws_security_group.gaming_app.id
  description              = "Istio/Envoy proxy communication for service mesh"
}

# Gaming app metrics for monitoring
resource "aws_security_group_rule" "gaming_app_metrics" {
  count = var.enable_gaming_metrics ? 1 : 0
  
  type                     = "ingress"
  from_port                = local.gaming_ports.metrics_port
  to_port                  = local.gaming_ports.metrics_port
  protocol                 = "tcp"
  source_security_group_id = var.create_monitoring_security_group ? aws_security_group.monitoring[0].id : aws_security_group.eks_nodes.id
  security_group_id        = aws_security_group.gaming_app.id
  description              = "Gaming application metrics collection"
}
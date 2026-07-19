# ==============================================================================
# NODE GROUPS MODULE - MAIN CONFIGURATION
# ==============================================================================
# Description: Comprehensive EKS node groups for gaming workloads
# Features: Gaming-optimized instance types, auto-scaling, mixed instances, spot instances
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
    Component = "eks-nodes"
    Module    = "compute"
  })

  # Gaming-optimized instance configurations by environment
  gaming_instance_config = {
    dev = {
      instance_types = ["t3.medium", "t3.large"]
      capacity_type  = "SPOT"
      min_size      = 1
      max_size      = 5
      desired_size  = 2
    }
    test = {
      instance_types = ["m5.large", "m5.xlarge", "c5.large"]
      capacity_type  = "ON_DEMAND"
      min_size      = 2
      max_size      = 10
      desired_size  = 3
    }
    prod = {
      instance_types = ["m5.xlarge", "m5.2xlarge", "c5.xlarge", "c5.2xlarge"]
      capacity_type  = "ON_DEMAND"
      min_size      = 3
      max_size      = 20
      desired_size  = 5
    }
  }

  # Gaming workload node group configuration
  node_group_config = local.gaming_instance_config[var.environment]
  
  # Custom user data for gaming optimizations
  gaming_user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    cluster_name        = var.cluster_name
    cluster_endpoint    = var.cluster_endpoint
    cluster_ca_data     = var.cluster_certificate_authority_data
    gaming_optimizations = var.gaming_optimizations
  }))
}

# ==============================================================================
# LAUNCH TEMPLATE FOR GAMING NODES
# ==============================================================================

resource "aws_launch_template" "gaming_nodes" {
  name_prefix   = "${local.name_prefix}-gaming-nodes-"
  description   = "Launch template for gaming EKS nodes with optimizations"
  
  vpc_security_group_ids = var.security_group_ids

  # Gaming-optimized instance configuration
  instance_type = local.node_group_config.instance_types[0]
  
  # Use EKS optimized AMI
  image_id = var.ami_id != "" ? var.ami_id : data.aws_ssm_parameter.eks_ami.value

  # Gaming workloads often need more resources
  instance_initiated_shutdown_behavior = "terminate"

  # Enhanced networking for gaming performance
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  # Network interfaces with gaming optimizations
  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    description                = "Primary network interface for gaming nodes"
    device_index               = 0
    security_groups            = var.security_group_ids
    
    # Gaming optimization: Enable enhanced networking
    interface_type = "efa"
  }

  # Block device mapping for gaming workloads
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.disk_size
      volume_type          = var.disk_type
      encrypted            = var.enable_ebs_encryption
      kms_key_id           = var.ebs_kms_key_id
      delete_on_termination = true
      
      # Gaming optimization: High IOPS for better performance
      iops       = var.disk_type == "gp3" ? var.disk_iops : null
      throughput = var.disk_type == "gp3" ? var.disk_throughput : null
    }
  }

  # User data for gaming optimizations
  user_data = var.enable_gaming_optimizations ? local.gaming_user_data : null

  # Instance monitoring
  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  # Tags for gaming infrastructure
  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-gaming-node"
      NodeGroup = "gaming-workloads"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-gaming-node-volume"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-gaming-nodes-lt"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ==============================================================================
# PRIMARY GAMING NODE GROUP
# ==============================================================================

resource "aws_eks_node_group" "gaming_primary" {
  cluster_name    = var.cluster_name
  node_group_name = "${local.name_prefix}-gaming-primary"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  version         = var.node_group_version

  # Instance configuration
  instance_types = local.node_group_config.instance_types
  capacity_type  = var.use_spot_instances ? "SPOT" : local.node_group_config.capacity_type
  disk_size      = var.disk_size

  # Auto-scaling configuration optimized for gaming workloads
  scaling_config {
    desired_size = local.node_group_config.desired_size
    max_size     = local.node_group_config.max_size
    min_size     = local.node_group_config.min_size
  }

  # Update configuration for gaming availability
  update_config {
    max_unavailable_percentage = var.max_unavailable_percentage
  }

  # Launch template with gaming optimizations
  launch_template {
    id      = aws_launch_template.gaming_nodes.id
    version = aws_launch_template.gaming_nodes.latest_version
  }

  # Gaming workload labels and taints
  labels = merge(var.node_labels, {
    "node.kubernetes.io/instance-type" = local.node_group_config.instance_types[0]
    "gaming.io/workload-type"          = "primary"
    "gaming.io/optimized"              = var.enable_gaming_optimizations ? "true" : "false"
    "node.kubernetes.io/capacity-type" = var.use_spot_instances ? "spot" : "on-demand"
  })

  # Taints for gaming workloads
  dynamic "taint" {
    for_each = var.gaming_taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  # Remote access configuration
  dynamic "remote_access" {
    for_each = var.enable_remote_access ? [1] : []
    content {
      ec2_ssh_key               = var.key_pair_name
      source_security_group_ids = var.remote_access_security_group_ids
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-gaming-primary"
    Purpose = "Gaming workloads primary compute"
  })

  # Ensure proper ordering
  depends_on = [aws_launch_template.gaming_nodes]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# ==============================================================================
# SPOT INSTANCES NODE GROUP (for cost optimization)
# ==============================================================================

resource "aws_eks_node_group" "gaming_spot" {
  count = var.enable_spot_node_group ? 1 : 0
  
  cluster_name    = var.cluster_name
  node_group_name = "${local.name_prefix}-gaming-spot"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  version         = var.node_group_version

  # Spot instance configuration
  instance_types = var.spot_instance_types
  capacity_type  = "SPOT"
  disk_size      = var.disk_size

  # More aggressive scaling for spot instances
  scaling_config {
    desired_size = var.spot_desired_size
    max_size     = var.spot_max_size
    min_size     = var.spot_min_size
  }

  # Faster replacement for spot instances
  update_config {
    max_unavailable_percentage = 50
  }

  # Launch template
  launch_template {
    id      = aws_launch_template.gaming_nodes.id
    version = aws_launch_template.gaming_nodes.latest_version
  }

  # Spot-specific labels
  labels = merge(var.node_labels, {
    "node.kubernetes.io/instance-type" = var.spot_instance_types[0]
    "gaming.io/workload-type"          = "spot"
    "gaming.io/cost-optimized"         = "true"
    "node.kubernetes.io/capacity-type" = "spot"
  })

  # Spot-specific taints
  taint {
    key    = "spot-instance"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-gaming-spot"
    Purpose = "Cost-optimized gaming workloads"
  })

  depends_on = [aws_launch_template.gaming_nodes]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# ==============================================================================
# GPU NODE GROUP (for advanced gaming features)
# ==============================================================================

resource "aws_eks_node_group" "gaming_gpu" {
  count = var.enable_gpu_node_group ? 1 : 0
  
  cluster_name    = var.cluster_name
  node_group_name = "${local.name_prefix}-gaming-gpu"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  version         = var.node_group_version

  # GPU instance configuration
  instance_types = var.gpu_instance_types
  capacity_type  = "ON_DEMAND"
  disk_size      = var.gpu_disk_size

  # Conservative scaling for expensive GPU instances
  scaling_config {
    desired_size = var.gpu_desired_size
    max_size     = var.gpu_max_size
    min_size     = var.gpu_min_size
  }

  update_config {
    max_unavailable_percentage = 25
  }

  # Launch template
  launch_template {
    id      = aws_launch_template.gaming_nodes.id
    version = aws_launch_template.gaming_nodes.latest_version
  }

  # GPU-specific labels
  labels = merge(var.node_labels, {
    "node.kubernetes.io/instance-type" = var.gpu_instance_types[0]
    "gaming.io/workload-type"          = "gpu"
    "gaming.io/accelerated"            = "true"
    "hardware-type"                    = "gpu"
  })

  # GPU-specific taints
  taint {
    key    = "nvidia.com/gpu"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-gaming-gpu"
    Purpose = "GPU-accelerated gaming workloads"
  })

  depends_on = [aws_launch_template.gaming_nodes]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# ==============================================================================
# ARM NODE GROUP (for cost optimization)
# ==============================================================================

resource "aws_eks_node_group" "gaming_arm" {
  count = var.enable_arm_node_group ? 1 : 0
  
  cluster_name    = var.cluster_name
  node_group_name = "${local.name_prefix}-gaming-arm"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  version         = var.node_group_version

  # ARM instance configuration
  instance_types = var.arm_instance_types
  capacity_type  = "ON_DEMAND"
  disk_size      = var.disk_size

  # Scaling configuration
  scaling_config {
    desired_size = var.arm_desired_size
    max_size     = var.arm_max_size
    min_size     = var.arm_min_size
  }

  update_config {
    max_unavailable_percentage = var.max_unavailable_percentage
  }

  # Launch template
  launch_template {
    id      = aws_launch_template.gaming_nodes.id
    version = aws_launch_template.gaming_nodes.latest_version
  }

  # ARM-specific labels
  labels = merge(var.node_labels, {
    "node.kubernetes.io/instance-type" = var.arm_instance_types[0]
    "gaming.io/workload-type"          = "arm"
    "gaming.io/cost-optimized"         = "true"
    "kubernetes.io/arch"               = "arm64"
  })

  # ARM-specific taints
  taint {
    key    = "kubernetes.io/arch"
    value  = "arm64"
    effect = "NO_SCHEDULE"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-gaming-arm"
    Purpose = "ARM-based cost-optimized gaming workloads"
  })

  depends_on = [aws_launch_template.gaming_nodes]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# ==============================================================================
# DATA SOURCES
# ==============================================================================

# Get EKS optimized AMI
data "aws_ssm_parameter" "eks_ami" {
  name = "/aws/service/eks/optimized-ami/${var.node_group_version}/amazon-linux-2/recommended/image_id"
}
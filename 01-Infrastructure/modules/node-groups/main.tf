# ==============================================================================
# NODE GROUPS MODULE - MAIN CONFIGURATION
# ==============================================================================
# Description: EKS node groups for gaming workloads
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
  common_tags = merge(var.tags, {
    Component = "node-groups"
    Module    = "compute"
  })
}

# ==============================================================================
# EKS NODE GROUPS
# ==============================================================================

resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  cluster_name    = var.cluster_name
  node_group_name = each.value.node_group_name
  node_role_arn   = var.node_group_role_arn
  
  # Select subnets based on subnet_type
  subnet_ids = each.value.subnet_type == "public" ? var.subnet_ids.public : (
    each.value.subnet_type == "database" ? var.subnet_ids.database : var.subnet_ids.private
  )

  capacity_type  = each.value.capacity_type
  instance_types = each.value.instance_types
  ami_type      = each.value.ami_type
  version       = each.value.kubernetes_version

  scaling_config {
    desired_size = each.value.desired_capacity
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  update_config {
    max_unavailable_percentage = each.value.update_config.max_unavailable_percentage
  }

  disk_size = each.value.disk_size

  dynamic "remote_access" {
    for_each = each.value.remote_access.ec2_ssh_key != "" ? [1] : []
    content {
      ec2_ssh_key               = each.value.remote_access.ec2_ssh_key
      source_security_group_ids = each.value.remote_access.source_security_group_ids
    }
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]

  labels = each.value.labels

  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = merge(local.common_tags, {
    Name = each.value.node_group_name
    Type = each.value.subnet_type
  })
}

# These are placeholder resources to satisfy dependencies
# In reality, these would be created by the IAM module
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = split("/", var.node_group_role_arn)[1]
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = split("/", var.node_group_role_arn)[1]
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = split("/", var.node_group_role_arn)[1]
}
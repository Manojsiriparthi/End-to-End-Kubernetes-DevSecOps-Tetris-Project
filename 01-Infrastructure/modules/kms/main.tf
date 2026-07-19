# ==============================================================================
# KMS MODULE - MAIN CONFIGURATION
# ==============================================================================
# Description: KMS encryption keys for gaming application security
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
    Component = "kms"
    Module    = "encryption"
  })
}

# ==============================================================================
# EKS CLUSTER KMS KEY
# ==============================================================================

resource "aws_kms_key" "cluster" {
  description             = "KMS key for EKS cluster encryption"
  deletion_window_in_days = var.environment == "prod" ? 30 : 7
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-eks-cluster-key"
    Usage = "eks-cluster-encryption"
  })
}

resource "aws_kms_alias" "cluster" {
  name          = "alias/${local.name_prefix}-eks-cluster"
  target_key_id = aws_kms_key.cluster.key_id
}

# ==============================================================================
# EBS KMS KEY (OPTIONAL)
# ==============================================================================

resource "aws_kms_key" "ebs" {
  count = var.create_ebs_kms_key ? 1 : 0
  
  description             = "KMS key for EBS volume encryption"
  deletion_window_in_days = var.environment == "prod" ? 30 : 7
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ebs-key"
    Usage = "ebs-encryption"
  })
}

resource "aws_kms_alias" "ebs" {
  count = var.create_ebs_kms_key ? 1 : 0
  
  name          = "alias/${local.name_prefix}-ebs"
  target_key_id = aws_kms_key.ebs[0].key_id
}
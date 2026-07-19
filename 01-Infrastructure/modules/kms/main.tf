# ==============================================================================
# KMS MODULE - MAIN CONFIGURATION
# ==============================================================================
# Description: Comprehensive KMS encryption keys for gaming infrastructure
# Features: EKS secrets encryption, EBS encryption, CloudWatch logs encryption
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
  
  # Current AWS account and region
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# ==============================================================================
# DATA SOURCES
# ==============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ==============================================================================
# EKS CLUSTER ENCRYPTION KEY
# ==============================================================================

resource "aws_kms_key" "eks_cluster" {
  count = var.create_eks_key ? 1 : 0
  
  description              = "KMS key for EKS cluster ${local.name_prefix} encryption"
  deletion_window_in_days  = var.deletion_window_in_days
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  
  # Enhanced security settings for production gaming environment
  enable_key_rotation = var.enable_key_rotation
  multi_region       = var.enable_multi_region

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${local.name_prefix}-eks-cluster-key-policy"
    Statement = [
      # Root access
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # EKS service access
      {
        Sid    = "Allow EKS Service"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
      },
      # Node group access for secrets
      {
        Sid    = "Allow EKS Node Group"
        Effect = "Allow"
        Principal = {
          AWS = var.node_group_role_arn != "" ? var.node_group_role_arn : "arn:aws:iam::${local.account_id}:role/${local.name_prefix}-*"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      # CloudWatch Logs access
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${local.region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/eks/${local.name_prefix}/*"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}-eks-cluster-key"
    Purpose     = "EKS cluster secrets and etcd encryption"
    Environment = var.environment
    KeyType     = "eks-cluster"
  })
}

resource "aws_kms_alias" "eks_cluster" {
  count = var.create_eks_key ? 1 : 0
  
  name          = "alias/${local.name_prefix}-eks-cluster"
  target_key_id = aws_kms_key.eks_cluster[0].key_id
}

# ==============================================================================
# EBS ENCRYPTION KEY
# ==============================================================================

resource "aws_kms_key" "ebs" {
  count = var.create_ebs_key ? 1 : 0
  
  description              = "KMS key for EBS volumes encryption in ${local.name_prefix}"
  deletion_window_in_days  = var.deletion_window_in_days
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  
  enable_key_rotation = var.enable_key_rotation
  multi_region       = var.enable_multi_region

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${local.name_prefix}-ebs-key-policy"
    Statement = [
      # Root access
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # EC2 service access for EBS encryption
      {
        Sid    = "Allow EC2 Service"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*",
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ec2.${local.region}.amazonaws.com"
          }
        }
      },
      # Auto Scaling service access
      {
        Sid    = "Allow AutoScaling Service"
        Effect = "Allow"
        Principal = {
          Service = "autoscaling.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*",
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ec2.${local.region}.amazonaws.com"
          }
        }
      },
      # EKS node group role access
      {
        Sid    = "Allow EKS Nodes"
        Effect = "Allow"
        Principal = {
          AWS = var.node_group_role_arn != "" ? var.node_group_role_arn : "arn:aws:iam::${local.account_id}:role/${local.name_prefix}-*"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ec2.${local.region}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}-ebs-key"
    Purpose     = "EBS volumes encryption for gaming workloads"
    Environment = var.environment
    KeyType     = "ebs-encryption"
  })
}

resource "aws_kms_alias" "ebs" {
  count = var.create_ebs_key ? 1 : 0
  
  name          = "alias/${local.name_prefix}-ebs"
  target_key_id = aws_kms_key.ebs[0].key_id
}

# ==============================================================================
# CLOUDWATCH LOGS ENCRYPTION KEY
# ==============================================================================

resource "aws_kms_key" "cloudwatch_logs" {
  count = var.create_cloudwatch_logs_key ? 1 : 0
  
  description              = "KMS key for CloudWatch Logs encryption in ${local.name_prefix}"
  deletion_window_in_days  = var.deletion_window_in_days
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  
  enable_key_rotation = var.enable_key_rotation
  multi_region       = var.enable_multi_region

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${local.name_prefix}-cloudwatch-logs-key-policy"
    Statement = [
      # Root access
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # CloudWatch Logs service access
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${local.region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/*"
          }
        }
      },
      # Gaming application access for custom logs
      {
        Sid    = "Allow Gaming Applications"
        Effect = "Allow"
        Principal = {
          AWS = var.gaming_role_arn != "" ? var.gaming_role_arn : "arn:aws:iam::${local.account_id}:role/${local.name_prefix}-gaming-*"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${local.region}:${local.account_id}:log-group:/gaming/*"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}-cloudwatch-logs-key"
    Purpose     = "CloudWatch Logs encryption for gaming telemetry"
    Environment = var.environment
    KeyType     = "cloudwatch-logs"
  })
}

resource "aws_kms_alias" "cloudwatch_logs" {
  count = var.create_cloudwatch_logs_key ? 1 : 0
  
  name          = "alias/${local.name_prefix}-cloudwatch-logs"
  target_key_id = aws_kms_key.cloudwatch_logs[0].key_id
}

# ==============================================================================
# SECRETS MANAGER ENCRYPTION KEY
# ==============================================================================

resource "aws_kms_key" "secrets_manager" {
  count = var.create_secrets_manager_key ? 1 : 0
  
  description              = "KMS key for Secrets Manager encryption in ${local.name_prefix}"
  deletion_window_in_days  = var.deletion_window_in_days
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  
  enable_key_rotation = var.enable_key_rotation
  multi_region       = var.enable_multi_region

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${local.name_prefix}-secrets-manager-key-policy"
    Statement = [
      # Root access
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # Secrets Manager service access
      {
        Sid    = "Allow Secrets Manager"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
      },
      # Gaming applications access for secrets
      {
        Sid    = "Allow Gaming Applications"
        Effect = "Allow"
        Principal = {
          AWS = var.gaming_role_arn != "" ? var.gaming_role_arn : "arn:aws:iam::${local.account_id}:role/${local.name_prefix}-gaming-*"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${local.region}.amazonaws.com"
          }
        }
      },
      # EKS nodes access for secrets
      {
        Sid    = "Allow EKS Nodes"
        Effect = "Allow"
        Principal = {
          AWS = var.node_group_role_arn != "" ? var.node_group_role_arn : "arn:aws:iam::${local.account_id}:role/${local.name_prefix}-*"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${local.region}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}-secrets-manager-key"
    Purpose     = "Secrets Manager encryption for gaming credentials"
    Environment = var.environment
    KeyType     = "secrets-manager"
  })
}

resource "aws_kms_alias" "secrets_manager" {
  count = var.create_secrets_manager_key ? 1 : 0
  
  name          = "alias/${local.name_prefix}-secrets-manager"
  target_key_id = aws_kms_key.secrets_manager[0].key_id
}

# ==============================================================================
# S3 ENCRYPTION KEY (for gaming assets, backups, logs)
# ==============================================================================

resource "aws_kms_key" "s3" {
  count = var.create_s3_key ? 1 : 0
  
  description              = "KMS key for S3 encryption in ${local.name_prefix}"
  deletion_window_in_days  = var.deletion_window_in_days
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  
  enable_key_rotation = var.enable_key_rotation
  multi_region       = var.enable_multi_region

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${local.name_prefix}-s3-key-policy"
    Statement = [
      # Root access
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # S3 service access
      {
        Sid    = "Allow S3 Service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
      },
      # Gaming applications access for assets
      {
        Sid    = "Allow Gaming Applications"
        Effect = "Allow"
        Principal = {
          AWS = var.gaming_role_arn != "" ? var.gaming_role_arn : "arn:aws:iam::${local.account_id}:role/${local.name_prefix}-gaming-*"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "s3.${local.region}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}-s3-key"
    Purpose     = "S3 encryption for gaming assets and backups"
    Environment = var.environment
    KeyType     = "s3-encryption"
  })
}

resource "aws_kms_alias" "s3" {
  count = var.create_s3_key ? 1 : 0
  
  name          = "alias/${local.name_prefix}-s3"
  target_key_id = aws_kms_key.s3[0].key_id
}

# ==============================================================================
# DYNAMODB ENCRYPTION KEY (for gaming session state and leaderboards)
# ==============================================================================

resource "aws_kms_key" "dynamodb" {
  count = var.create_dynamodb_key ? 1 : 0
  
  description              = "KMS key for DynamoDB encryption in ${local.name_prefix}"
  deletion_window_in_days  = var.deletion_window_in_days
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  
  enable_key_rotation = var.enable_key_rotation
  multi_region       = var.enable_multi_region

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${local.name_prefix}-dynamodb-key-policy"
    Statement = [
      # Root access
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # DynamoDB service access
      {
        Sid    = "Allow DynamoDB Service"
        Effect = "Allow"
        Principal = {
          Service = "dynamodb.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*",
          "kms:CreateGrant"
        ]
        Resource = "*"
      },
      # Gaming applications access for session data
      {
        Sid    = "Allow Gaming Applications"
        Effect = "Allow"
        Principal = {
          AWS = var.gaming_role_arn != "" ? var.gaming_role_arn : "arn:aws:iam::${local.account_id}:role/${local.name_prefix}-gaming-*"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "dynamodb.${local.region}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}-dynamodb-key"
    Purpose     = "DynamoDB encryption for gaming session state and leaderboards"
    Environment = var.environment
    KeyType     = "dynamodb-encryption"
  })
}

resource "aws_kms_alias" "dynamodb" {
  count = var.create_dynamodb_key ? 1 : 0
  
  name          = "alias/${local.name_prefix}-dynamodb"
  target_key_id = aws_kms_key.dynamodb[0].key_id
}

# ==============================================================================
# KMS KEY GRANTS (for cross-service access)
# ==============================================================================

# Grant for EKS to use the cluster key
resource "aws_kms_grant" "eks_cluster_grant" {
  count = var.create_eks_key && var.cluster_service_role_arn != "" ? 1 : 0
  
  name              = "${local.name_prefix}-eks-cluster-grant"
  key_id            = aws_kms_key.eks_cluster[0].key_id
  grantee_principal = var.cluster_service_role_arn
  operations        = ["Decrypt", "Encrypt", "GenerateDataKey", "ReEncryptFrom", "ReEncryptTo", "CreateGrant", "DescribeKey"]

  constraints {
    encryption_context_equals = {
      "aws:eks:cluster-name" = local.name_prefix
    }
  }
}

# ==============================================================================
# DEFAULT EBS ENCRYPTION CONFIGURATION
# ==============================================================================

resource "aws_ebs_default_kms_key" "default" {
  count = var.create_ebs_key && var.set_ebs_default_key ? 1 : 0
  
  key_arn = aws_kms_key.ebs[0].arn
}

resource "aws_ebs_encryption_by_default" "default" {
  count = var.create_ebs_key && var.enable_ebs_encryption_by_default ? 1 : 0
  
  enabled = true
}
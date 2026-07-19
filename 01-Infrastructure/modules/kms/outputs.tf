# ==============================================================================
# KMS MODULE - OUTPUTS
# ==============================================================================
# Description: Output values for KMS module
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

# ==============================================================================
# EKS CLUSTER KEY OUTPUTS
# ==============================================================================

output "eks_cluster_key_id" {
  description = "ID of the EKS cluster KMS key"
  value       = var.create_eks_key ? aws_kms_key.eks_cluster[0].id : null
}

output "eks_cluster_key_arn" {
  description = "ARN of the EKS cluster KMS key"
  value       = var.create_eks_key ? aws_kms_key.eks_cluster[0].arn : null
}

output "eks_cluster_key_alias" {
  description = "Alias of the EKS cluster KMS key"
  value       = var.create_eks_key ? aws_kms_alias.eks_cluster[0].name : null
}

output "eks_cluster_key_alias_arn" {
  description = "ARN of the EKS cluster KMS key alias"
  value       = var.create_eks_key ? aws_kms_alias.eks_cluster[0].arn : null
}

# ==============================================================================
# EBS KEY OUTPUTS
# ==============================================================================

output "ebs_key_id" {
  description = "ID of the EBS KMS key"
  value       = var.create_ebs_key ? aws_kms_key.ebs[0].id : null
}

output "ebs_key_arn" {
  description = "ARN of the EBS KMS key"
  value       = var.create_ebs_key ? aws_kms_key.ebs[0].arn : null
}

output "ebs_key_alias" {
  description = "Alias of the EBS KMS key"
  value       = var.create_ebs_key ? aws_kms_alias.ebs[0].name : null
}

output "ebs_key_alias_arn" {
  description = "ARN of the EBS KMS key alias"
  value       = var.create_ebs_key ? aws_kms_alias.ebs[0].arn : null
}

# ==============================================================================
# CLOUDWATCH LOGS KEY OUTPUTS
# ==============================================================================

output "cloudwatch_logs_key_id" {
  description = "ID of the CloudWatch Logs KMS key"
  value       = var.create_cloudwatch_logs_key ? aws_kms_key.cloudwatch_logs[0].id : null
}

output "cloudwatch_logs_key_arn" {
  description = "ARN of the CloudWatch Logs KMS key"
  value       = var.create_cloudwatch_logs_key ? aws_kms_key.cloudwatch_logs[0].arn : null
}

output "cloudwatch_logs_key_alias" {
  description = "Alias of the CloudWatch Logs KMS key"
  value       = var.create_cloudwatch_logs_key ? aws_kms_alias.cloudwatch_logs[0].name : null
}

output "cloudwatch_logs_key_alias_arn" {
  description = "ARN of the CloudWatch Logs KMS key alias"
  value       = var.create_cloudwatch_logs_key ? aws_kms_alias.cloudwatch_logs[0].arn : null
}

# ==============================================================================
# SECRETS MANAGER KEY OUTPUTS
# ==============================================================================

output "secrets_manager_key_id" {
  description = "ID of the Secrets Manager KMS key"
  value       = var.create_secrets_manager_key ? aws_kms_key.secrets_manager[0].id : null
}

output "secrets_manager_key_arn" {
  description = "ARN of the Secrets Manager KMS key"
  value       = var.create_secrets_manager_key ? aws_kms_key.secrets_manager[0].arn : null
}

output "secrets_manager_key_alias" {
  description = "Alias of the Secrets Manager KMS key"
  value       = var.create_secrets_manager_key ? aws_kms_alias.secrets_manager[0].name : null
}

output "secrets_manager_key_alias_arn" {
  description = "ARN of the Secrets Manager KMS key alias"
  value       = var.create_secrets_manager_key ? aws_kms_alias.secrets_manager[0].arn : null
}

# ==============================================================================
# S3 KEY OUTPUTS
# ==============================================================================

output "s3_key_id" {
  description = "ID of the S3 KMS key"
  value       = var.create_s3_key ? aws_kms_key.s3[0].id : null
}

output "s3_key_arn" {
  description = "ARN of the S3 KMS key"
  value       = var.create_s3_key ? aws_kms_key.s3[0].arn : null
}

output "s3_key_alias" {
  description = "Alias of the S3 KMS key"
  value       = var.create_s3_key ? aws_kms_alias.s3[0].name : null
}

output "s3_key_alias_arn" {
  description = "ARN of the S3 KMS key alias"
  value       = var.create_s3_key ? aws_kms_alias.s3[0].arn : null
}

# ==============================================================================
# DYNAMODB KEY OUTPUTS
# ==============================================================================

output "dynamodb_key_id" {
  description = "ID of the DynamoDB KMS key"
  value       = var.create_dynamodb_key ? aws_kms_key.dynamodb[0].id : null
}

output "dynamodb_key_arn" {
  description = "ARN of the DynamoDB KMS key"
  value       = var.create_dynamodb_key ? aws_kms_key.dynamodb[0].arn : null
}

output "dynamodb_key_alias" {
  description = "Alias of the DynamoDB KMS key"
  value       = var.create_dynamodb_key ? aws_kms_alias.dynamodb[0].name : null
}

output "dynamodb_key_alias_arn" {
  description = "ARN of the DynamoDB KMS key alias"
  value       = var.create_dynamodb_key ? aws_kms_alias.dynamodb[0].arn : null
}

# ==============================================================================
# KEY MAPPING OUTPUTS (for easy reference)
# ==============================================================================

output "key_mappings" {
  description = "Mapping of service names to their KMS key ARNs"
  value = {
    eks_cluster      = var.create_eks_key ? aws_kms_key.eks_cluster[0].arn : null
    ebs             = var.create_ebs_key ? aws_kms_key.ebs[0].arn : null
    cloudwatch_logs = var.create_cloudwatch_logs_key ? aws_kms_key.cloudwatch_logs[0].arn : null
    secrets_manager = var.create_secrets_manager_key ? aws_kms_key.secrets_manager[0].arn : null
    s3              = var.create_s3_key ? aws_kms_key.s3[0].arn : null
    dynamodb        = var.create_dynamodb_key ? aws_kms_key.dynamodb[0].arn : null
  }
}

output "key_alias_mappings" {
  description = "Mapping of service names to their KMS key alias names"
  value = {
    eks_cluster      = var.create_eks_key ? aws_kms_alias.eks_cluster[0].name : null
    ebs             = var.create_ebs_key ? aws_kms_alias.ebs[0].name : null
    cloudwatch_logs = var.create_cloudwatch_logs_key ? aws_kms_alias.cloudwatch_logs[0].name : null
    secrets_manager = var.create_secrets_manager_key ? aws_kms_alias.secrets_manager[0].name : null
    s3              = var.create_s3_key ? aws_kms_alias.s3[0].name : null
    dynamodb        = var.create_dynamodb_key ? aws_kms_alias.dynamodb[0].name : null
  }
}

# ==============================================================================
# GAMING INFRASTRUCTURE OUTPUTS
# ==============================================================================

output "gaming_encryption_summary" {
  description = "Summary of encryption configuration for gaming infrastructure"
  value = {
    keys_created = {
      eks_cluster      = var.create_eks_key
      ebs             = var.create_ebs_key
      cloudwatch_logs = var.create_cloudwatch_logs_key
      secrets_manager = var.create_secrets_manager_key
      s3              = var.create_s3_key
      dynamodb        = var.create_dynamodb_key
    }
    encryption_features = {
      key_rotation_enabled = var.enable_key_rotation
      multi_region_keys   = var.enable_multi_region
      ebs_default_encryption = var.enable_ebs_encryption_by_default
      session_data_encrypted = var.gaming_encryption_requirements.encrypt_session_data
      player_data_encrypted  = var.gaming_encryption_requirements.encrypt_player_data
      game_assets_encrypted  = var.gaming_encryption_requirements.encrypt_game_assets
      telemetry_encrypted    = var.gaming_encryption_requirements.encrypt_telemetry
      backups_encrypted      = var.gaming_encryption_requirements.encrypt_backups
    }
    security_config = {
      deletion_window_days = var.deletion_window_in_days
      grants_enabled      = var.security_config.enable_key_grants
      via_service_condition = var.security_config.enable_via_service_condition
    }
  }
}

# ==============================================================================
# EBS ENCRYPTION DEFAULTS
# ==============================================================================

output "ebs_encryption_configuration" {
  description = "EBS encryption configuration status"
  value = {
    default_key_set    = var.create_ebs_key && var.set_ebs_default_key
    encryption_enabled = var.create_ebs_key && var.enable_ebs_encryption_by_default
    key_arn           = var.create_ebs_key ? aws_kms_key.ebs[0].arn : null
  }
}

# ==============================================================================
# GRANT OUTPUTS
# ==============================================================================

output "eks_cluster_grant_id" {
  description = "ID of the EKS cluster KMS grant"
  value = var.create_eks_key && var.cluster_service_role_arn != "" ? aws_kms_grant.eks_cluster_grant[0].key_id : null
}

# ==============================================================================
# COMPLIANCE AND AUDIT OUTPUTS
# ==============================================================================

output "compliance_summary" {
  description = "Compliance and audit summary for KMS configuration"
  value = {
    environment = var.environment
    total_keys_created = (
      (var.create_eks_key ? 1 : 0) +
      (var.create_ebs_key ? 1 : 0) +
      (var.create_cloudwatch_logs_key ? 1 : 0) +
      (var.create_secrets_manager_key ? 1 : 0) +
      (var.create_s3_key ? 1 : 0) +
      (var.create_dynamodb_key ? 1 : 0)
    )
    key_rotation_enabled = var.enable_key_rotation
    deletion_protection_days = var.deletion_window_in_days
    multi_region_deployment = var.enable_multi_region
    compliance_logging = var.environment_config.enable_compliance_logging
  }
}
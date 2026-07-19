# ==============================================================================
# KMS MODULE - OUTPUTS
# ==============================================================================

output "cluster_kms_key_arn" {
  description = "ARN of the EKS cluster KMS key"
  value       = aws_kms_key.cluster.arn
}

output "cluster_kms_key_id" {
  description = "ID of the EKS cluster KMS key"
  value       = aws_kms_key.cluster.key_id
}

output "ebs_kms_key_arn" {
  description = "ARN of the EBS KMS key"
  value       = var.create_ebs_kms_key ? aws_kms_key.ebs[0].arn : null
}

output "ebs_kms_key_id" {
  description = "ID of the EBS KMS key"
  value       = var.create_ebs_kms_key ? aws_kms_key.ebs[0].key_id : null
}
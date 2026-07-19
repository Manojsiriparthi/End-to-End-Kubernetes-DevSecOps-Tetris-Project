# ==============================================================================
# SECURITY GROUPS MODULE - OUTPUTS
# ==============================================================================

output "bastion_sg_id" {
  description = "Security group ID for bastion host"
  value       = aws_security_group.bastion.id
}

output "eks_cluster_additional_sg_id" {
  description = "Additional security group ID for EKS cluster"
  value       = aws_security_group.eks_cluster_additional.id
}

output "eks_nodes_sg_id" {
  description = "Security group ID for EKS nodes"
  value       = aws_security_group.eks_nodes.id
}

output "alb_sg_id" {
  description = "Security group ID for Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "database_sg_id" {
  description = "Security group ID for database"
  value       = aws_security_group.database.id
}
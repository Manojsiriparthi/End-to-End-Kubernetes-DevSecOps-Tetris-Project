# ==============================================================================
# IAM MODULE - OUTPUTS
# ==============================================================================

output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster service role"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_node_group_role_arn" {
  description = "ARN of the EKS node group role"
  value       = aws_iam_role.eks_node_group.arn
}

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller role"
  value       = try(aws_iam_role.aws_load_balancer_controller.arn, null)
}
# ==============================================================================
# NODE GROUPS MODULE - OUTPUTS
# ==============================================================================

output "node_groups" {
  description = "Map of node group configurations and their status"
  value = {
    for k, v in aws_eks_node_group.main : k => {
      node_group_arn    = v.arn
      node_group_status = v.status
      capacity_type     = v.capacity_type
      instance_types    = v.instance_types
      ami_type         = v.ami_type
      node_group_resources = v.resources
    }
  }
}
# ==============================================================================
# NODE GROUPS MODULE - VARIABLES
# ==============================================================================

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "node_group_role_arn" {
  description = "ARN of the EKS node group IAM role"
  type        = string
}

variable "subnet_ids" {
  description = "Map of subnet IDs by type"
  type = object({
    public   = list(string)
    private  = list(string)
    database = list(string)
  })
}

variable "worker_security_group_id" {
  description = "Security group ID for worker nodes"
  type        = string
  default     = ""
}

variable "additional_security_group_ids" {
  description = "List of additional security group IDs"
  type        = list(string)
  default     = []
}

variable "enable_bootstrap_user_data" {
  description = "Enable bootstrap user data"
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "KMS key ID for EBS encryption"
  type        = string
  default     = null
}

variable "node_groups" {
  description = "Configuration for EKS node groups"
  type = map(object({
    node_group_name = string
    subnet_type     = string
    
    instance_types = list(string)
    ami_type      = string
    capacity_type = string
    
    min_size         = number
    max_size         = number
    desired_capacity = number
    
    disk_size    = number
    disk_type    = string
    disk_encrypted = bool
    
    remote_access = object({
      ec2_ssh_key               = string
      source_security_group_ids = list(string)
    })
    
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    
    labels = map(string)
    
    update_config = object({
      max_unavailable_percentage = number
    })
    
    enable_monitoring = bool
    kubernetes_version = string
  }))
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
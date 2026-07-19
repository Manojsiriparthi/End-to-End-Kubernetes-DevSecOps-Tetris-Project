# ==============================================================================
# KMS MODULE - VARIABLES
# ==============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

variable "create_ebs_kms_key" {
  description = "Whether to create EBS KMS key"
  type        = bool
  default     = false
}
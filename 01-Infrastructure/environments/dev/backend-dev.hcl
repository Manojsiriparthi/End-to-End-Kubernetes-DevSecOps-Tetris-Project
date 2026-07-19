# ==============================================================================
# DEV ENVIRONMENT - TERRAFORM BACKEND CONFIGURATION
# ==============================================================================
# Description: Backend configuration for development environment state management
# Environment: Development
# Usage: terraform init -backend-config=backend-dev.hcl
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

# S3 Backend Configuration for Development
bucket         = "tetris-platform-terraform-state-dev"
key            = "gaming-infrastructure/dev/terraform.tfstate"
region         = "us-west-2"
encrypt        = true
dynamodb_table = "tetris-platform-terraform-locks-dev"

# State Locking and Consistency
dynamodb_table = "tetris-platform-terraform-locks-dev"

# Workspace Management
workspace_key_prefix = "gaming-environments"

# Access Control
# Note: Ensure the S3 bucket and DynamoDB table exist before running terraform init
# The bucket should have versioning enabled and appropriate access policies

# Development-specific settings
# - Relaxed access controls for development team
# - Shorter retention policies for cost optimization
# - Single region deployment
# ==============================================================================
# TEST ENVIRONMENT - TERRAFORM BACKEND CONFIGURATION
# ==============================================================================
# Description: S3 backend with native file locking for test environment
# Environment: Test
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

terraform {
  backend "s3" {
    bucket = "manoj-gaming-app"
    key    = "infrastructure/test/terraform.tfstate"
    region = "us-east-1"
    
    # Native file locking (no DynamoDB required)
    use_lockfile = true
    
    # Security
    encrypt = true
    
    # Workspace isolation
    workspace_key_prefix = "gaming-env"
  }
}

# ==============================================================================
# BACKEND SETUP NOTES FOR TEST
# ==============================================================================
# Same bucket as dev but different key path for isolation:
# - Dev:  infrastructure/dev/terraform.tfstate
# - Test: infrastructure/test/terraform.tfstate
# - Prod: infrastructure/prod/terraform.tfstate
#
# Native file locking provides:
# - Automatic state locking
# - No additional AWS costs
# - Simplified permissions
# ==============================================================================
# ==============================================================================
# DEV ENVIRONMENT - TERRAFORM BACKEND CONFIGURATION
# ==============================================================================
# Description: S3 backend with native file locking for development environment
# Environment: Development
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

terraform {
  backend "s3" {
    bucket = "manoj-gaming-app"
    key    = "infrastructure/dev/terraform.tfstate"
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
# BACKEND SETUP INSTRUCTIONS FOR DEV
# ==============================================================================
# 1. Create S3 bucket for state storage:
#    aws s3 mb s3://manoj-gaming-app --region us-east-1
#
# 2. Enable versioning on the bucket:
#    aws s3api put-bucket-versioning \
#      --bucket manoj-gaming-app \
#      --versioning-configuration Status=Enabled
#
# 3. Initialize Terraform (no DynamoDB needed):
#    terraform init
#
# 4. Benefits of native file locking:
#    - No additional AWS resources (cost savings)
#    - Simpler configuration
#    - No DynamoDB permissions required
#    - Built-in conflict detection
#
# ==============================================================================
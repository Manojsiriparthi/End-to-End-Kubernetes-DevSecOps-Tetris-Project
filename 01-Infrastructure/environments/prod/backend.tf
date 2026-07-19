# ==============================================================================
# PRODUCTION ENVIRONMENT - TERRAFORM BACKEND CONFIGURATION
# ==============================================================================
# Description: S3 backend with native file locking for production environment
# Environment: Production
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

terraform {
  backend "s3" {
    bucket = "manoj-gaming-app"
    key    = "infrastructure/prod/terraform.tfstate"
    region = "us-east-1"
    
    # Native file locking (recommended for production)
    use_lockfile = true
    
    # Enhanced security for production
    encrypt = true
    use_path_style = false
    
    # Workspace isolation
    workspace_key_prefix = "gaming-env"
  }
}

# ==============================================================================
# PRODUCTION BACKEND SECURITY CONSIDERATIONS
# ==============================================================================
# For production, ensure additional security:
# 1. Enable MFA delete on the S3 bucket
# 2. Enable server-side encryption with KMS
# 3. Set up proper IAM policies for access control
# 4. Enable CloudTrail for state file access auditing
#
# Native file locking benefits for production:
# - No additional infrastructure to manage
# - Reduced failure points (no DynamoDB dependency)
# - Lower operational complexity
# - Built-in atomic operations
# ==============================================================================
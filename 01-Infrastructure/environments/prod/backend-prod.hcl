# ==============================================================================
# PRODUCTION ENVIRONMENT - TERRAFORM BACKEND CONFIGURATION
# ==============================================================================
# Description: S3 backend configuration for production environment
# Environment: Production
# Usage: terraform init -backend-config=backend-prod.hcl
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

# S3 Backend Configuration for Production Environment
bucket         = "tetris-platform-terraform-state-prod"
key            = "infrastructure/prod/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "tetris-platform-terraform-locks-prod"
encrypt        = true

# Production-specific configuration
# workspace_key_prefix = "prod"

# ==============================================================================
# BACKEND SETUP INSTRUCTIONS FOR PRODUCTION
# ==============================================================================
# 1. Create S3 bucket for state storage with enhanced security:
#    aws s3 mb s3://tetris-platform-terraform-state-prod --region us-west-2
#
# 2. Enable versioning on the bucket:
#    aws s3api put-bucket-versioning \
#      --bucket tetris-platform-terraform-state-prod \
#      --versioning-configuration Status=Enabled
#
# 3. Enable server-side encryption with KMS:
#    aws s3api put-bucket-encryption \
#      --bucket tetris-platform-terraform-state-prod \
#      --server-side-encryption-configuration \
#      '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms","KMSMasterKeyID":"alias/terraform-state"}}]}'
#
# 4. Enable MFA Delete (PRODUCTION SECURITY):
#    aws s3api put-bucket-versioning \
#      --bucket tetris-platform-terraform-state-prod \
#      --versioning-configuration Status=Enabled,MfaDelete=Enabled \
#      --mfa "SERIAL_NUMBER TOKEN"
#
# 5. Block all public access (PRODUCTION SECURITY):
#    aws s3api put-public-access-block \
#      --bucket tetris-platform-terraform-state-prod \
#      --public-access-block-configuration \
#      "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
#
# 6. Create DynamoDB table for state locking with encryption:
#    aws dynamodb create-table \
#      --table-name tetris-platform-terraform-locks-prod \
#      --attribute-definitions AttributeName=LockID,AttributeType=S \
#      --key-schema AttributeName=LockID,KeyType=HASH \
#      --provisioned-throughput ReadCapacityUnits=20,WriteCapacityUnits=20 \
#      --sse-specification Enabled=true,SSEType=KMS,KMSMasterKeyId=alias/terraform-locks \
#      --region us-west-2
#
# 7. Initialize Terraform with this backend:
#    terraform init -backend-config=backend-prod.hcl
#
# ==============================================================================
# PRODUCTION SECURITY CONSIDERATIONS
# ==============================================================================
# - State bucket has MFA delete protection
# - KMS encryption for both S3 and DynamoDB
# - All public access blocked
# - Higher DynamoDB capacity for team concurrency
# - Separate KMS keys for different data types
# ==============================================================================
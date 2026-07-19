# ==============================================================================
# TEST ENVIRONMENT - TERRAFORM BACKEND CONFIGURATION
# ==============================================================================
# Description: S3 backend configuration for test environment
# Environment: Test
# Usage: terraform init -backend-config=backend-test.hcl
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

# S3 Backend Configuration for Test Environment
bucket         = "tetris-platform-terraform-state-test"
key            = "infrastructure/test/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "tetris-platform-terraform-locks-test"
encrypt        = true

# Optional: Workspace isolation for testing different features
# workspace_key_prefix = "test-environments"

# ==============================================================================
# BACKEND SETUP INSTRUCTIONS FOR TEST
# ==============================================================================
# 1. Create S3 bucket for state storage:
#    aws s3 mb s3://tetris-platform-terraform-state-test --region us-west-2
#
# 2. Enable versioning on the bucket:
#    aws s3api put-bucket-versioning \
#      --bucket tetris-platform-terraform-state-test \
#      --versioning-configuration Status=Enabled
#
# 3. Enable server-side encryption:
#    aws s3api put-bucket-encryption \
#      --bucket tetris-platform-terraform-state-test \
#      --server-side-encryption-configuration \
#      '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
#
# 4. Create DynamoDB table for state locking:
#    aws dynamodb create-table \
#      --table-name tetris-platform-terraform-locks-test \
#      --attribute-definitions AttributeName=LockID,AttributeType=S \
#      --key-schema AttributeName=LockID,KeyType=HASH \
#      --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=10 \
#      --region us-west-2
#
# 5. Initialize Terraform with this backend:
#    terraform init -backend-config=backend-test.hcl
#
# ==============================================================================
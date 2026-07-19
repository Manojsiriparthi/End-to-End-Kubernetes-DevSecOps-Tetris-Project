# ==============================================================================
# PRODUCTION EKS ADDONS - TERRAFORM BACKEND CONFIGURATION
# ==============================================================================
# Description: S3 backend configuration for production EKS addons
# Environment: Production
# Usage: terraform init -backend-config=backend-prod.hcl
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

# S3 Backend Configuration for Production EKS Addons
bucket         = "tetris-platform-terraform-state-prod"
key            = "eks-addons/prod/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "tetris-platform-terraform-locks-prod"
encrypt        = true

# Production-specific configuration
# workspace_key_prefix = "addons"

# ==============================================================================
# BACKEND SETUP INSTRUCTIONS FOR PRODUCTION ADDONS
# ==============================================================================
# Note: This uses the same bucket as infrastructure but different key path
# 
# 1. Bucket already created during infrastructure setup
#
# 2. Initialize Terraform with this backend:
#    terraform init -backend-config=backend-prod.hcl
#
# 3. Verify state separation:
#    - Infrastructure: infrastructure/prod/terraform.tfstate
#    - EKS Addons: eks-addons/prod/terraform.tfstate
#
# ==============================================================================
# PRODUCTION ADDON DEPLOYMENT WORKFLOW
# ==============================================================================
# 1. Deploy infrastructure first:
#    cd 01-Infrastructure/environments/prod
#    terraform init -backend-config=backend-prod.hcl
#    terraform plan -var-file=terraform.tfvars
#    terraform apply -var-file=terraform.tfvars
#
# 2. Deploy EKS addons after infrastructure:
#    cd 02-eks-addons/environments/prod
#    terraform init -backend-config=backend-prod.hcl
#    terraform plan -var-file=terraform.tfvars
#    terraform apply -var-file=terraform.tfvars
#
# 3. Verify addon deployment:
#    kubectl get pods -A
#    kubectl get nodes
#    kubectl get gateways -A
#
# ==============================================================================
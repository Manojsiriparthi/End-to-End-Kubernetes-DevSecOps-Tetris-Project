# ==============================================================================
# DEV EKS ADDONS - TERRAFORM BACKEND CONFIGURATION
# ==============================================================================
# Description: S3 backend configuration for development EKS addons
# Environment: Development
# Usage: terraform init -backend-config=backend-dev.hcl
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

# S3 Backend Configuration for Dev EKS Addons
bucket         = "tetris-platform-terraform-state-dev"
key            = "eks-addons/dev/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "tetris-platform-terraform-locks-dev"
encrypt        = true

# ==============================================================================
# DEV ADDON DEPLOYMENT WORKFLOW
# ==============================================================================
# 1. Deploy infrastructure first:
#    cd 01-Infrastructure/environments/dev
#    terraform init -backend-config=backend-dev.hcl
#    terraform plan -var-file=terraform.tfvars
#    terraform apply -var-file=terraform.tfvars
#
# 2. Deploy EKS addons after infrastructure:
#    cd 02-eks-addons/environments/dev
#    terraform init -backend-config=backend-dev.hcl
#    terraform plan -var-file=terraform.tfvars
#    terraform apply -var-file=terraform.tfvars
#
# 3. Test gaming features:
#    kubectl port-forward svc/tetris-game 8080:80
#    curl -H "Connection: Upgrade" -H "Upgrade: websocket" http://localhost:8080/ws
#
# ==============================================================================
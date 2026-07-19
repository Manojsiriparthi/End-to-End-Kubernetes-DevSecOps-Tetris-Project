# ==============================================================================
# PRODUCTION EKS ADDONS - TERRAFORM BACKEND CONFIGURATION
# ==============================================================================
# Description: S3 backend with native file locking for production EKS addons
# Environment: Production
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

terraform {
  backend "s3" {
    bucket = "manoj-gaming-app"
    key    = "eks-addons/prod/terraform.tfstate"
    region = "us-east-1"
    
    # Native file locking for production reliability
    use_lockfile = true
    
    # Enhanced security
    encrypt = true
    use_path_style = false
    
    # Workspace isolation
    workspace_key_prefix = "addons-env"
  }
}

# ==============================================================================
# PRODUCTION ADDON DEPLOYMENT WORKFLOW
# ==============================================================================
# 1. Deploy infrastructure first:
#    cd 01-Infrastructure/environments/prod
#    terraform init
#    terraform plan -var-file=terraform.tfvars
#    terraform apply -var-file=terraform.tfvars
#
# 2. Deploy EKS addons after infrastructure:
#    cd 02-eks-addons/environments/prod
#    terraform init
#    terraform plan -var-file=terraform.tfvars
#    terraform apply -var-file=terraform.tfvars
#
# 3. Verify addon deployment:
#    kubectl get pods -A
#    kubectl get nodes
#    kubectl get gateways -A
#
# ==============================================================================
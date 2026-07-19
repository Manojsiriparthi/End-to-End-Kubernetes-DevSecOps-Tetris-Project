# ==============================================================================
# DEV EKS ADDONS - TERRAFORM BACKEND CONFIGURATION
# ==============================================================================
# Description: S3 backend with native file locking for dev EKS addons
# Environment: Development
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

terraform {
  backend "s3" {
    bucket = "manoj-gaming-app"
    key    = "eks-addons/dev/terraform.tfstate"
    region = "us-east-1"
    
    # Native file locking
    use_lockfile = true
    
    # Security
    encrypt = true
    use_path_style = false
    
    # Workspace isolation
    workspace_key_prefix = "addons-env"
  }
}

# ==============================================================================
# DEV ADDON DEPLOYMENT WORKFLOW
# ==============================================================================
# 1. Deploy infrastructure first:
#    cd 01-Infrastructure/environments/dev
#    terraform init
#    terraform plan -var-file=terraform.tfvars
#    terraform apply -var-file=terraform.tfvars
#
# 2. Deploy EKS addons after infrastructure:
#    cd 02-eks-addons/environments/dev
#    terraform init
#    terraform plan -var-file=terraform.tfvars
#    terraform apply -var-file=terraform.tfvars
#
# 3. Test gaming features:
#    kubectl port-forward svc/tetris-game 8080:80
#    curl -H "Connection: Upgrade" -H "Upgrade: websocket" http://localhost:8080/ws
#
# ==============================================================================
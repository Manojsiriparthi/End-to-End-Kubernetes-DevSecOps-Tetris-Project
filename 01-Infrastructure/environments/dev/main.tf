# ==============================================================================
# DEV ENVIRONMENT - MAIN CONFIGURATION
# ==============================================================================
# Description: Development environment EKS infrastructure
# Environment: Development
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# ==============================================================================
# PROVIDER CONFIGURATIONS
# ==============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# ==============================================================================
# LOCAL VALUES AND COMMON TAGS
# ==============================================================================

locals {
  environment = "dev"
  name_prefix = "${var.project_name}-${local.environment}"
  
  common_tags = {
    Project         = var.project_name
    Environment     = local.environment
    Owner           = var.owner
    ManagedBy      = "terraform"
    CreatedDate    = formatdate("YYYY-MM-DD", timestamp())
    CostCenter     = var.cost_center
    BusinessUnit   = var.business_unit
    BackupRequired = "false"
    Compliance     = "low"
  }

  # Availability Zones
  availability_zones = data.aws_availability_zones.available.names

  # CIDR Calculations for multi-AZ deployment
  public_subnet_cidrs = [
    for i, az in slice(local.availability_zones, 0, 3) : 
    cidrsubnet(var.vpc_cidr, 8, i + 1)
  ]
  
  private_subnet_cidrs = [
    for i, az in slice(local.availability_zones, 0, 3) : 
    cidrsubnet(var.vpc_cidr, 8, i + 10)
  ]
  
  database_subnet_cidrs = [
    for i, az in slice(local.availability_zones, 0, 3) : 
    cidrsubnet(var.vpc_cidr, 8, i + 20)
  ]
}

# ==============================================================================
# DATA SOURCES
# ==============================================================================

data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ==============================================================================
# LAYER 1: NETWORKING MODULE WITH PROPER DEPENDENCY MANAGEMENT
# ==============================================================================

module "networking" {
  source = "../../modules/networking"

  # Basic Configuration
  project_name       = var.project_name
  environment        = local.environment
  vpc_cidr          = var.vpc_cidr
  availability_zones = slice(local.availability_zones, 0, 3)

  # Subnet Configurations
  public_subnet_cidrs   = local.public_subnet_cidrs
  private_subnet_cidrs  = local.private_subnet_cidrs
  database_subnet_cidrs = local.database_subnet_cidrs

  # Dev-specific configuration
  enable_dns_hostnames     = true
  enable_dns_support       = true
  enable_nat_gateway       = true
  single_nat_gateway       = true
  enable_vpn_gateway       = false
  create_database_subnet_group = true
  enable_flow_logs         = false

  tags = local.common_tags
  
  # Dependency management to ensure clean destroy
  depends_on = []  # Networking is Layer 1, no dependencies
}

# ==============================================================================
# LAYER 1: KMS MODULE
# ==============================================================================

module "kms" {
  source = "../../modules/kms"

  project_name = var.project_name
  environment  = local.environment
  create_ebs_kms_key = false
  
  tags = local.common_tags
}

# ==============================================================================
# LAYER 1: SECURITY GROUPS MODULE
# ==============================================================================

module "security_groups" {
  source = "../../modules/security-groups"

  project_name = var.project_name
  environment  = local.environment
  vpc_id       = module.networking.vpc_id
  vpc_cidr_block       = module.networking.vpc_cidr_block
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
  
  tags = local.common_tags
  depends_on = [module.networking]
}

# ==============================================================================
# LAYER 1: BASIC IAM ROLES (EKS PREREQUISITES - NO OIDC DEPENDENCY)
# ==============================================================================

# EKS Cluster Service Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "${local.name_prefix}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-eks-cluster-role"
    Component = "iam"
    Layer = "basic"
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS Node Group Role
resource "aws_iam_role" "eks_node_group_role" {
  name = "${local.name_prefix}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-eks-node-group-role"
    Component = "iam"
    Layer = "basic"
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

# ==============================================================================
# LAYER 2: EKS CLUSTER MODULE (USES BASIC IAM ROLES)
# ==============================================================================

module "eks_cluster" {
  source = "../../modules/eks-cluster"

  cluster_name    = local.name_prefix
  cluster_version = var.eks_cluster_version
  cluster_service_role_arn = aws_iam_role.eks_cluster_role.arn

  subnet_ids = concat(module.networking.private_subnet_ids, module.networking.public_subnet_ids)
  
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  additional_security_group_ids = [
    module.security_groups.eks_cluster_additional_sg_id
  ]

  cluster_enabled_log_types = ["api", "audit"]
  cloudwatch_log_group_retention_in_days = 7

  enable_irsa = true

  cluster_encryption_config = [{
    provider_key_arn = module.kms.cluster_kms_key_arn
    resources        = ["secrets"]
  }]

  tags = local.common_tags

  depends_on = [
    module.networking,
    module.security_groups,
    aws_iam_role.eks_cluster_role,
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# ==============================================================================
# LAYER 2: NODE GROUPS MODULE (USES BASIC IAM ROLES)
# ==============================================================================

module "node_groups" {
  source = "../../modules/node-groups"

  cluster_name = module.eks_cluster.cluster_name
  node_group_role_arn = aws_iam_role.eks_node_group_role.arn
  
  subnet_ids = {
    public   = module.networking.public_subnet_ids
    private  = module.networking.private_subnet_ids
    database = module.networking.database_subnet_ids
  }

  node_groups = var.node_group_configs

  worker_security_group_id = module.eks_cluster.node_security_group_id
  additional_security_group_ids = [
    module.security_groups.eks_nodes_sg_id
  ]

  enable_bootstrap_user_data = true
  kms_key_id = module.kms.ebs_kms_key_id

  tags = local.common_tags

  depends_on = [
    module.eks_cluster,
    aws_iam_role.eks_node_group_role,
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy
  ]
}

# ==============================================================================
# LAYER 3: ADVANCED IAM ROLES (IRSA - POST-EKS CREATION)
# ==============================================================================

# OIDC Provider Data (after EKS cluster exists)
data "tls_certificate" "cluster" {
  url = module.eks_cluster.cluster_oidc_issuer_url

  depends_on = [module.eks_cluster]
}

# AWS Load Balancer Controller IRSA Role
data "aws_iam_policy_document" "aws_load_balancer_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks_cluster.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      identifiers = [module.eks_cluster.oidc_provider_arn]
      type        = "Federated"
    }
  }

  depends_on = [module.eks_cluster]
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  assume_role_policy = data.aws_iam_policy_document.aws_load_balancer_controller_assume_role_policy.json
  name               = "${local.name_prefix}-aws-load-balancer-controller"
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-aws-load-balancer-controller"
    Component = "iam"
    Layer = "irsa"
  })

  depends_on = [module.eks_cluster]
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  policy = file("${path.root}/../../modules/iam/policies/aws_load_balancer_controller_iam_policy.json")
  name   = "${local.name_prefix}-AWSLoadBalancerControllerIAMPolicy"
  
  tags = merge(local.common_tags, {
    Component = "iam"
    Layer = "irsa"
  })
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
  role       = aws_iam_role.aws_load_balancer_controller.name
}

# ==============================================================================
# KUBERNETES PROVIDER CONFIGURATION (AFTER EKS CLUSTER EXISTS)
# ==============================================================================

# Data sources for cluster info (after cluster creation)
data "aws_eks_cluster" "cluster" {
  name = module.eks_cluster.cluster_name
  depends_on = [module.eks_cluster]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.cluster_name
  depends_on = [module.eks_cluster]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
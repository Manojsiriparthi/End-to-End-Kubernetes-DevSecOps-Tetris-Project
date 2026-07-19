# ==============================================================================
# IAM MODULE - MAIN CONFIGURATION
# ==============================================================================
# Description: Comprehensive IAM roles, policies, and service accounts for EKS and gaming infrastructure
# Features: EKS service roles, node group roles, OIDC provider, gaming-specific policies
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ==============================================================================
# LOCAL VALUES
# ==============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = merge(var.tags, {
    Component = "iam"
    Module    = "security"
  })

  # Gaming-specific policy statements
  gaming_policies = {
    # Real-time gaming metrics and monitoring
    gaming_metrics = [
      "cloudwatch:PutMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups"
    ]
    
    # Gaming session management
    session_management = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem"
    ]
    
    # Real-time communication (WebSocket, ElastiCache)
    realtime_communication = [
      "elasticache:DescribeCacheClusters",
      "elasticache:DescribeReplicationGroups",
      "apigateway:*",
      "execute-api:*"
    ]
    
    # Auto-scaling for gaming workloads
    gaming_autoscaling = [
      "application-autoscaling:*",
      "ecs:DescribeServices",
      "ecs:UpdateService",
      "eks:DescribeCluster",
      "eks:DescribeNodegroup"
    ]
  }
}

# ==============================================================================
# EKS CLUSTER SERVICE ROLE
# ==============================================================================

resource "aws_iam_role" "eks_cluster_service_role" {
  name = "${local.name_prefix}-eks-cluster-service-role"

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
    Name = "${local.name_prefix}-eks-cluster-service-role"
    Purpose = "EKS cluster service operations"
  })
}

# EKS Cluster Service Policy
resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_service_role.name
}

# VPC Resource Controller Policy (for load balancer management)
resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_service_role.name
}

# ==============================================================================
# EKS NODE GROUP ROLE
# ==============================================================================

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
    Purpose = "EKS worker nodes operations"
  })
}

# Node Group Required Policies
resource "aws_iam_role_policy_attachment" "eks_node_group_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

# EBS CSI Driver Policy for persistent volumes
resource "aws_iam_role_policy_attachment" "eks_node_group_AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

# ==============================================================================
# GAMING-SPECIFIC IAM POLICIES
# ==============================================================================

# Gaming Application Policy for real-time features
resource "aws_iam_policy" "gaming_application_policy" {
  name        = "${local.name_prefix}-gaming-application-policy"
  description = "Policy for gaming application with real-time features"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudWatch metrics for game performance monitoring
      {
        Effect = "Allow"
        Action = local.gaming_policies.gaming_metrics
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      },
      # DynamoDB for session management and leaderboards
      {
        Effect = "Allow"
        Action = local.gaming_policies.session_management
        Resource = [
          "arn:aws:dynamodb:${var.aws_region}:*:table/${local.name_prefix}-*",
          "arn:aws:dynamodb:${var.aws_region}:*:table/${local.name_prefix}-*/index/*"
        ]
      },
      # ElastiCache for real-time game state
      {
        Effect = "Allow"
        Action = local.gaming_policies.realtime_communication
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      },
      # Auto-scaling for player load management
      {
        Effect = "Allow"
        Action = local.gaming_policies.gaming_autoscaling
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-gaming-application-policy"
    Purpose = "Gaming application permissions"
  })
}

# ==============================================================================
# LOAD BALANCER CONTROLLER ROLE
# ==============================================================================

resource "aws_iam_role" "aws_load_balancer_controller_role" {
  count = var.create_load_balancer_controller_role ? 1 : 0
  
  name = "${local.name_prefix}-aws-load-balancer-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${replace(var.oidc_provider_arn, "/^(.*provider/)/", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-aws-load-balancer-controller-role"
    Purpose = "AWS Load Balancer Controller"
  })
}

# Load Balancer Controller Policy
resource "aws_iam_policy" "aws_load_balancer_controller_policy" {
  count = var.create_load_balancer_controller_role ? 1 : 0
  
  name        = "${local.name_prefix}-aws-load-balancer-controller-policy"
  description = "Policy for AWS Load Balancer Controller"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeCoipPools",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:DescribeProtection",
          "shield:GetSubscriptionState",
          "shield:DescribeSubscription",
          "shield:CreateProtection",
          "shield:DeleteProtection"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags"
        ]
        Resource = "arn:aws:ec2:*:*:security-group/*"
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = "CreateSecurityGroup"
          }
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ]
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "true"
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ]
        Resource = "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:SetWebAcl",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:ModifyRule"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_policy_attachment" {
  count = var.create_load_balancer_controller_role ? 1 : 0
  
  policy_arn = aws_iam_policy.aws_load_balancer_controller_policy[0].arn
  role       = aws_iam_role.aws_load_balancer_controller_role[0].name
}

# ==============================================================================
# CLUSTER AUTOSCALER ROLE
# ==============================================================================

resource "aws_iam_role" "cluster_autoscaler_role" {
  count = var.create_cluster_autoscaler_role ? 1 : 0
  
  name = "${local.name_prefix}-cluster-autoscaler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
            "${replace(var.oidc_provider_arn, "/^(.*provider/)/", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cluster-autoscaler-role"
    Purpose = "Cluster Autoscaler"
  })
}

# Cluster Autoscaler Policy
resource "aws_iam_policy" "cluster_autoscaler_policy" {
  count = var.create_cluster_autoscaler_role ? 1 : 0
  
  name        = "${local.name_prefix}-cluster-autoscaler-policy"
  description = "Policy for Cluster Autoscaler with gaming workload optimization"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeInstanceTypes"
        ]
        Resource = "*"
      },
      # Gaming-specific: Allow rapid scaling for player spikes
      {
        Effect = "Allow"
        Action = [
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:SuspendProcesses",
          "autoscaling:ResumeProcesses"
        ]
        Resource = "arn:aws:autoscaling:${var.aws_region}:*:autoScalingGroup:*:autoScalingGroupName/${local.name_prefix}-*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler_policy_attachment" {
  count = var.create_cluster_autoscaler_role ? 1 : 0
  
  policy_arn = aws_iam_policy.cluster_autoscaler_policy[0].arn
  role       = aws_iam_role.cluster_autoscaler_role[0].name
}

# ==============================================================================
# EBS CSI DRIVER ROLE
# ==============================================================================

resource "aws_iam_role" "ebs_csi_driver_role" {
  count = var.create_ebs_csi_driver_role ? 1 : 0
  
  name = "${local.name_prefix}-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${replace(var.oidc_provider_arn, "/^(.*provider/)/", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ebs-csi-driver-role"
    Purpose = "EBS CSI Driver"
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy_attachment" {
  count = var.create_ebs_csi_driver_role ? 1 : 0
  
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver_role[0].name
}

# ==============================================================================
# EXTERNAL DNS ROLE
# ==============================================================================

resource "aws_iam_role" "external_dns_role" {
  count = var.create_external_dns_role ? 1 : 0
  
  name = "${local.name_prefix}-external-dns-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:kube-system:external-dns"
            "${replace(var.oidc_provider_arn, "/^(.*provider/)/", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-external-dns-role"
    Purpose = "External DNS"
  })
}

# External DNS Policy
resource "aws_iam_policy" "external_dns_policy" {
  count = var.create_external_dns_role ? 1 : 0
  
  name        = "${local.name_prefix}-external-dns-policy"
  description = "Policy for External DNS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = [
          "arn:aws:route53:::hostedzone/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ]
        Resource = [
          "*"
        ]
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "external_dns_policy_attachment" {
  count = var.create_external_dns_role ? 1 : 0
  
  policy_arn = aws_iam_policy.external_dns_policy[0].arn
  role       = aws_iam_role.external_dns_role[0].name
}

# ==============================================================================
# GAMING WORKLOAD ROLE (Application Level)
# ==============================================================================

resource "aws_iam_role" "gaming_workload_role" {
  count = var.create_gaming_workload_role ? 1 : 0
  
  name = "${local.name_prefix}-gaming-workload-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:gaming:tetris-app"
            "${replace(var.oidc_provider_arn, "/^(.*provider/)/", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-gaming-workload-role"
    Purpose = "Gaming Application Workloads"
  })
}

resource "aws_iam_role_policy_attachment" "gaming_workload_policy_attachment" {
  count = var.create_gaming_workload_role ? 1 : 0
  
  policy_arn = aws_iam_policy.gaming_application_policy.arn
  role       = aws_iam_role.gaming_workload_role[0].name
}

# ==============================================================================
# INSTANCE PROFILES
# ==============================================================================

resource "aws_iam_instance_profile" "eks_node_group_instance_profile" {
  name = "${local.name_prefix}-eks-node-group-instance-profile"
  role = aws_iam_role.eks_node_group_role.name

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-eks-node-group-instance-profile"
  })
}

# ==============================================================================
# ADDITIONAL POLICIES FOR GAMING INFRASTRUCTURE
# ==============================================================================

# CloudWatch Container Insights Policy
resource "aws_iam_policy" "cloudwatch_container_insights_policy" {
  count = var.enable_container_insights ? 1 : 0
  
  name        = "${local.name_prefix}-cloudwatch-container-insights-policy"
  description = "Policy for CloudWatch Container Insights"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

# Attach Container Insights policy to node group role
resource "aws_iam_role_policy_attachment" "cloudwatch_container_insights_policy_attachment" {
  count = var.enable_container_insights ? 1 : 0
  
  policy_arn = aws_iam_policy.cloudwatch_container_insights_policy[0].arn
  role       = aws_iam_role.eks_node_group_role.name
}
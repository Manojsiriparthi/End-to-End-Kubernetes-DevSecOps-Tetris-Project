# ==============================================================================
# NETWORKING MODULE - MAIN CONFIGURATION
# ==============================================================================
# Description: High Availability VPC with public, private, and database subnets
# Features: Multi-AZ, NAT Gateways, Internet Gateway, Route Tables, NACLs, Security
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
  
  # Create AZ mappings for consistent naming
  az_mappings = {
    for idx, az in var.availability_zones : az => {
      index = idx
      suffix = substr(az, -1, 1)  # Gets the last character (a, b, c)
    }
  }
  
  # Common tags for all networking resources
  common_tags = merge(var.tags, {
    Component = "networking"
    Module    = "vpc"
  })
}

# ==============================================================================
# VPC CONFIGURATION
# ==============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
    Type = "main-vpc"
  })
}

# ==============================================================================
# INTERNET GATEWAY
# ==============================================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

# ==============================================================================
# PUBLIC SUBNETS
# ==============================================================================

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block             = var.public_subnet_cidrs[count.index]
  availability_zone      = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-subnet-${local.az_mappings[var.availability_zones[count.index]].suffix}"
    Type = "public"
    Zone = var.availability_zones[count.index]
    
    # Kubernetes cluster discovery tags
    "kubernetes.io/cluster/${local.name_prefix}" = "shared"
    "kubernetes.io/role/elb"                     = "1"
    
    # Subnet tier for load balancer placement
    "subnet-tier" = "public"
    
    # Network planning
    "network-tier" = "web"
    "internet-facing" = "true"
  })
}

# ==============================================================================
# PRIVATE SUBNETS
# ==============================================================================

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-subnet-${local.az_mappings[var.availability_zones[count.index]].suffix}"
    Type = "private"
    Zone = var.availability_zones[count.index]
    
    # Kubernetes cluster discovery tags
    "kubernetes.io/cluster/${local.name_prefix}" = "shared"
    "kubernetes.io/role/internal-elb"            = "1"
    
    # Subnet tier for internal load balancer placement
    "subnet-tier" = "private"
    
    # Network planning
    "network-tier" = "application"
    "internet-facing" = "false"
  })
}

# ==============================================================================
# DATABASE SUBNETS
# ==============================================================================

resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-database-subnet-${local.az_mappings[var.availability_zones[count.index]].suffix}"
    Type = "database"
    Zone = var.availability_zones[count.index]
    
    # Database tier specific tags
    "subnet-tier" = "database"
    "network-tier" = "data"
    "internet-facing" = "false"
    
    # Data protection
    "data-classification" = "sensitive"
    "backup-required" = "true"
  })
}

# ==============================================================================
# DATABASE SUBNET GROUP
# ==============================================================================

resource "aws_db_subnet_group" "database" {
  count = var.create_database_subnet_group ? 1 : 0

  name       = "${local.name_prefix}-database-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-database-subnet-group"
  })
}

# ==============================================================================
# ELASTIC IP ADDRESSES FOR NAT GATEWAYS
# ==============================================================================

resource "aws_eip" "nat" {
  count = var.single_nat_gateway ? 1 : length(var.availability_zones)

  domain = "vpc"
  
  tags = merge(local.common_tags, {
    Name = var.single_nat_gateway ? 
           "${local.name_prefix}-nat-eip" : 
           "${local.name_prefix}-nat-eip-${local.az_mappings[var.availability_zones[count.index]].suffix}"
  })

  depends_on = [aws_internet_gateway.main]
}

# ==============================================================================
# NAT GATEWAYS
# ==============================================================================

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.common_tags, {
    Name = var.single_nat_gateway ? 
           "${local.name_prefix}-nat-gw" : 
           "${local.name_prefix}-nat-gw-${local.az_mappings[var.availability_zones[count.index]].suffix}"
  })

  depends_on = [aws_internet_gateway.main]
}

# ==============================================================================
# ROUTE TABLES - PUBLIC
# ==============================================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rt"
    Type = "public"
  })
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id            = aws_internet_gateway.main.id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ==============================================================================
# ROUTE TABLES - PRIVATE
# ==============================================================================

resource "aws_route_table" "private" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : length(var.availability_zones)

  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = var.single_nat_gateway ? 
           "${local.name_prefix}-private-rt" : 
           "${local.name_prefix}-private-rt-${local.az_mappings[var.availability_zones[count.index]].suffix}"
    Type = "private"
  })
}

resource "aws_route" "private_nat_gateway" {
  count = var.enable_nat_gateway ? length(aws_route_table.private) : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[var.single_nat_gateway ? 0 : count.index].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id
}

# ==============================================================================
# ROUTE TABLES - DATABASE
# ==============================================================================

resource "aws_route_table" "database" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-database-rt-${local.az_mappings[var.availability_zones[count.index]].suffix}"
    Type = "database"
  })
}

resource "aws_route_table_association" "database" {
  count = length(aws_subnet.database)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[count.index].id
}

# ==============================================================================
# VPN GATEWAY (OPTIONAL)
# ==============================================================================

resource "aws_vpn_gateway" "main" {
  count = var.enable_vpn_gateway ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpn-gw"
  })
}

resource "aws_vpn_gateway_attachment" "main" {
  count = var.enable_vpn_gateway ? 1 : 0

  vpc_id         = aws_vpc.main.id
  vpn_gateway_id = aws_vpn_gateway.main[0].id
}

# ==============================================================================
# VPC FLOW LOGS
# ==============================================================================

resource "aws_flow_log" "vpc" {
  count = var.enable_flow_logs ? 1 : 0

  iam_role_arn    = aws_iam_role.flow_log[0].arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/flowlogs/${local.name_prefix}"
  retention_in_days = var.flow_logs_retention_in_days

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc-flow-logs"
  })
}

resource "aws_iam_role" "flow_log" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${local.name_prefix}-vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "flow_log" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${local.name_prefix}-vpc-flow-log-policy"
  role = aws_iam_role.flow_log[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
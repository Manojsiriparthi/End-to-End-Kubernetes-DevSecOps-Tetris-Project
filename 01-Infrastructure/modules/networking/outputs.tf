# ==============================================================================
# NETWORKING MODULE - OUTPUTS
# ==============================================================================
# Description: Output values for networking module
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

# ==============================================================================
# VPC OUTPUTS
# ==============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_instance_tenancy" {
  description = "Tenancy of instances spin up within VPC"
  value       = aws_vpc.main.instance_tenancy
}

output "vpc_enable_dns_support" {
  description = "Whether or not the VPC has DNS support"
  value       = aws_vpc.main.enable_dns_support
}

output "vpc_enable_dns_hostnames" {
  description = "Whether or not the VPC has DNS hostname support"
  value       = aws_vpc.main.enable_dns_hostnames
}

output "vpc_main_route_table_id" {
  description = "ID of the main route table associated with this VPC"
  value       = aws_vpc.main.main_route_table_id
}

output "vpc_default_network_acl_id" {
  description = "ID of the default network ACL"
  value       = aws_vpc.main.default_network_acl_id
}

output "vpc_default_security_group_id" {
  description = "ID of the security group created by default on VPC creation"
  value       = aws_vpc.main.default_security_group_id
}

output "vpc_default_route_table_id" {
  description = "ID of the default route table"
  value       = aws_vpc.main.default_route_table_id
}

# ==============================================================================
# INTERNET GATEWAY OUTPUTS
# ==============================================================================

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = try(aws_internet_gateway.main.id, null)
}

output "internet_gateway_arn" {
  description = "ARN of the Internet Gateway"
  value       = try(aws_internet_gateway.main.arn, null)
}

# ==============================================================================
# SUBNET OUTPUTS
# ==============================================================================

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = aws_subnet.public[*].arn
}

output "public_subnets_cidr_blocks" {
  description = "List of CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = aws_subnet.private[*].arn
}

output "private_subnets_cidr_blocks" {
  description = "List of CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = aws_subnet.database[*].id
}

output "database_subnet_ids" {
  description = "List of IDs of database subnets"
  value       = aws_subnet.database[*].id
}

output "database_subnet_arns" {
  description = "List of ARNs of database subnets"
  value       = aws_subnet.database[*].arn
}

output "database_subnets_cidr_blocks" {
  description = "List of CIDR blocks of database subnets"
  value       = aws_subnet.database[*].cidr_block
}

output "database_subnet_group" {
  description = "ID of database subnet group"
  value       = try(aws_db_subnet_group.database[0].id, null)
}

output "database_subnet_group_name" {
  description = "Name of database subnet group"
  value       = try(aws_db_subnet_group.database[0].name, null)
}

# ==============================================================================
# AVAILABILITY ZONE OUTPUTS
# ==============================================================================

output "availability_zones" {
  description = "List of availability zones used by subnets"
  value       = var.availability_zones
}

output "public_subnet_azs" {
  description = "List of availability zones of public subnets"
  value       = aws_subnet.public[*].availability_zone
}

output "private_subnet_azs" {
  description = "List of availability zones of private subnets"
  value       = aws_subnet.private[*].availability_zone
}

output "database_subnet_azs" {
  description = "List of availability zones of database subnets"
  value       = aws_subnet.database[*].availability_zone
}

# ==============================================================================
# NAT GATEWAY OUTPUTS
# ==============================================================================

output "nat_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = aws_eip.nat[*].public_ip
}

output "natgw_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

# ==============================================================================
# ROUTE TABLE OUTPUTS
# ==============================================================================

output "public_route_table_ids" {
  description = "List of IDs of the public route tables"
  value       = [aws_route_table.public.id]
}

output "private_route_table_ids" {
  description = "List of IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

output "database_route_table_ids" {
  description = "List of IDs of the database route tables"
  value       = aws_route_table.database[*].id
}

output "public_internet_gateway_route_id" {
  description = "ID of the internet gateway route"
  value       = try(aws_route.public_internet_gateway.id, null)
}

output "private_nat_gateway_route_ids" {
  description = "List of IDs of the private nat gateway route"
  value       = aws_route.private_nat_gateway[*].id
}

# ==============================================================================
# VPN GATEWAY OUTPUTS
# ==============================================================================

output "vpn_gateway_id" {
  description = "ID of the VPN Gateway"
  value       = try(aws_vpn_gateway.main[0].id, null)
}

output "vpn_gateway_arn" {
  description = "ARN of the VPN Gateway"
  value       = try(aws_vpn_gateway.main[0].arn, null)
}

# ==============================================================================
# FLOW LOGS OUTPUTS
# ==============================================================================

output "vpc_flow_log_id" {
  description = "ID of the Flow Log resource"
  value       = try(aws_flow_log.vpc[0].id, null)
}

output "vpc_flow_log_cloudwatch_iam_role_arn" {
  description = "ARN of the IAM role used when pushing logs to Cloudwatch log group"
  value       = try(aws_iam_role.flow_log[0].arn, null)
}

# ==============================================================================
# NETWORK MAPPING OUTPUTS (FOR EKS AND APPLICATIONS)
# ==============================================================================

output "subnet_mappings" {
  description = "Mapping of subnet types to their IDs and availability zones"
  value = {
    public = {
      subnet_ids = aws_subnet.public[*].id
      azs        = aws_subnet.public[*].availability_zone
      cidrs      = aws_subnet.public[*].cidr_block
    }
    private = {
      subnet_ids = aws_subnet.private[*].id
      azs        = aws_subnet.private[*].availability_zone
      cidrs      = aws_subnet.private[*].cidr_block
    }
    database = {
      subnet_ids = aws_subnet.database[*].id
      azs        = aws_subnet.database[*].availability_zone
      cidrs      = aws_subnet.database[*].cidr_block
    }
  }
}

# ==============================================================================
# KUBERNETES INTEGRATION OUTPUTS
# ==============================================================================

output "eks_cluster_subnet_ids" {
  description = "Subnet IDs suitable for EKS cluster (private + public for mixed mode)"
  value       = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
}

output "eks_private_subnet_ids" {
  description = "Private subnet IDs for EKS worker nodes"
  value       = aws_subnet.private[*].id
}

output "eks_public_subnet_ids" {
  description = "Public subnet IDs for EKS load balancers"
  value       = aws_subnet.public[*].id
}

# ==============================================================================
# COST OPTIMIZATION OUTPUTS
# ==============================================================================

output "cost_optimization_summary" {
  description = "Summary of cost optimization features used"
  value = {
    single_nat_gateway = var.single_nat_gateway
    nat_gateway_count  = length(aws_nat_gateway.main)
    flow_logs_enabled  = var.enable_flow_logs
    vpn_gateway_enabled = var.enable_vpn_gateway
    estimated_monthly_nat_cost = length(aws_nat_gateway.main) * 45.0  # Rough estimate
  }
}

# ==============================================================================
# SECURITY OUTPUTS
# ==============================================================================

output "network_security_summary" {
  description = "Summary of network security features"
  value = {
    flow_logs_enabled = var.enable_flow_logs
    network_firewall_enabled = var.enable_network_firewall
    dedicated_database_subnets = length(aws_subnet.database) > 0
    multi_az_deployment = length(var.availability_zones) > 1
  }
}
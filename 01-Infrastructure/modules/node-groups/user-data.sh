#!/bin/bash

# ==============================================================================
# EKS NODE USER DATA - GAMING OPTIMIZATIONS
# ==============================================================================
# Description: User data script for EKS nodes with gaming optimizations
# Author: Platform Engineering Team
# Version: 1.0.0
# ==============================================================================

set -ex

# Variables passed from Terraform
CLUSTER_NAME="${cluster_name}"
CLUSTER_ENDPOINT="${cluster_endpoint}"
CLUSTER_CA_DATA="${cluster_ca_data}"

# Gaming optimizations flag
ENABLE_GAMING_OPTS="${gaming_optimizations.enable_low_latency}"
ENABLE_NETWORK_PERF="${gaming_optimizations.enable_enhanced_networking}"
ENABLE_CPU_PERF="${gaming_optimizations.enable_cpu_optimizations}"

# ==============================================================================
# SYSTEM OPTIMIZATIONS FOR GAMING WORKLOADS
# ==============================================================================

# Update system packages
yum update -y

# Install additional packages for gaming workloads
yum install -y \
    htop \
    iotop \
    nethogs \
    tcpdump \
    strace \
    perf \
    numactl \
    irqbalance

# ==============================================================================
# NETWORK OPTIMIZATIONS
# ==============================================================================

if [[ "$ENABLE_NETWORK_PERF" == "true" ]]; then
    echo "Applying network optimizations for gaming workloads..."
    
    # Optimize network buffer sizes
    cat >> /etc/sysctl.conf << EOF
# Gaming network optimizations
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr

# Reduce network latency
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1

# Increase connection limits for gaming
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.core.netdev_max_backlog = 5000

# Optimize for high connection count
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_keepalive_probes = 7
net.ipv4.tcp_keepalive_intvl = 30
EOF

    # Apply sysctl settings
    sysctl -p
fi

# ==============================================================================
# CPU AND MEMORY OPTIMIZATIONS
# ==============================================================================

if [[ "$ENABLE_CPU_PERF" == "true" ]]; then
    echo "Applying CPU optimizations for gaming workloads..."
    
    # Set CPU governor to performance mode for consistent latency
    echo 'GOVERNOR="performance"' > /etc/default/cpufrequtils
    
    # Disable CPU power saving features that can introduce latency
    cat >> /etc/sysctl.conf << EOF
# CPU optimizations for gaming
kernel.numa_balancing = 0
vm.swappiness = 1
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
kernel.sched_migration_cost_ns = 5000000
kernel.sched_autogroup_enabled = 0
EOF

    # Configure IRQ balancing for gaming workloads
    systemctl enable irqbalance
    systemctl start irqbalance
fi

# ==============================================================================
# LOW LATENCY OPTIMIZATIONS
# ==============================================================================

if [[ "$ENABLE_GAMING_OPTS" == "true" ]]; then
    echo "Applying low latency optimizations for gaming..."
    
    # Disable unnecessary services that can cause jitter
    systemctl disable bluetooth
    systemctl disable cups
    
    # Configure kernel for low latency
    cat >> /etc/sysctl.conf << EOF
# Low latency gaming optimizations
kernel.sched_rt_runtime_us = 950000
kernel.sched_rt_period_us = 1000000
kernel.timer_migration = 0
EOF

    # Set real-time limits for gaming processes
    cat >> /etc/security/limits.conf << EOF
# Real-time limits for gaming workloads
*               soft    rtprio          99
*               hard    rtprio          99
*               soft    memlock         unlimited
*               hard    memlock         unlimited
EOF
fi

# ==============================================================================
# CONTAINER RUNTIME OPTIMIZATIONS
# ==============================================================================

# Configure containerd for gaming workloads
mkdir -p /etc/containerd
cat > /etc/containerd/config.toml << EOF
version = 2

[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    sandbox_image = "602401143452.dkr.ecr.us-east-1.amazonaws.com/eks/pause:3.5"
    
    [plugins."io.containerd.grpc.v1.cri".containerd]
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true

    [plugins."io.containerd.grpc.v1.cri".registry]
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."602401143452.dkr.ecr.us-east-1.amazonaws.com"]
          endpoint = ["https://602401143452.dkr.ecr.us-east-1.amazonaws.com"]
EOF

# Restart containerd to apply configuration
systemctl restart containerd

# ==============================================================================
# KUBERNETES KUBELET CONFIGURATION
# ==============================================================================

# Configure kubelet for gaming workloads
mkdir -p /etc/kubernetes/kubelet
cat > /etc/kubernetes/kubelet/kubelet-config.json << EOF
{
  "kind": "KubeletConfiguration",
  "apiVersion": "kubelet.config.k8s.io/v1beta1",
  "address": "0.0.0.0",
  "authentication": {
    "anonymous": {
      "enabled": false
    },
    "webhook": {
      "cacheTTL": "2m0s",
      "enabled": true
    },
    "x509": {
      "clientCAFile": "/etc/kubernetes/pki/ca.crt"
    }
  },
  "authorization": {
    "mode": "Webhook",
    "webhook": {
      "cacheAuthorizedTTL": "5m0s",
      "cacheUnauthorizedTTL": "30s"
    }
  },
  "clusterDomain": "cluster.local",
  "hairpinMode": "hairpin-veth",
  "readOnlyPort": 0,
  "cgroupDriver": "systemd",
  "cgroupsPerQOS": true,
  "enforceNodeAllocatable": ["pods"],
  "kubeReserved": {
    "cpu": "100m",
    "memory": "100Mi",
    "ephemeral-storage": "1Gi"
  },
  "systemReserved": {
    "cpu": "100m",
    "memory": "100Mi",
    "ephemeral-storage": "1Gi"
  },
  "maxPods": 110,
  "podPidsLimit": 4096,
  "resolvConf": "/etc/resolv.conf",
  "rotateServerCertificates": true,
  "serverTLSBootstrap": true,
  "tlsCipherSuites": [
    "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256",
    "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
    "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305",
    "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
    "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305",
    "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
  ],
  "tlsMinVersion": "VersionTLS12"
}
EOF

# ==============================================================================
# EKS BOOTSTRAP
# ==============================================================================

# Bootstrap the node to the EKS cluster with gaming optimizations
/etc/eks/bootstrap.sh \
  "$CLUSTER_NAME" \
  --b64-cluster-ca "$CLUSTER_CA_DATA" \
  --apiserver-endpoint "$CLUSTER_ENDPOINT" \
  --kubelet-extra-args "--node-labels=gaming.io/optimized=true,gaming.io/user-data-version=1.0" \
  --use-max-pods false \
  --container-runtime containerd

# ==============================================================================
# POST-BOOTSTRAP OPTIMIZATIONS
# ==============================================================================

# Wait for kubelet to be ready
sleep 30

# Install AWS CLI v2 for gaming operations
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Install kubectl for troubleshooting
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.29.0/2024-01-04/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin

# ==============================================================================
# MONITORING AGENT SETUP
# ==============================================================================

# Install CloudWatch agent for gaming metrics
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
rm -f ./amazon-cloudwatch-agent.rpm

# Configure CloudWatch agent for gaming metrics
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "agent": {
        "metrics_collection_interval": 10
    },
    "metrics": {
        "namespace": "Gaming/EKS/NodeMetrics",
        "metrics_collected": {
            "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 10,
                "totalcpu": true
            },
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 10,
                "resources": ["*"]
            },
            "diskio": {
                "measurement": ["io_time", "read_bytes", "write_bytes", "reads", "writes"],
                "metrics_collection_interval": 10,
                "resources": ["*"]
            },
            "mem": {
                "measurement": ["mem_used_percent", "mem_available_percent"],
                "metrics_collection_interval": 10
            },
            "netstat": {
                "measurement": ["tcp_established", "tcp_time_wait"],
                "metrics_collection_interval": 10
            },
            "net": {
                "measurement": ["bytes_sent", "bytes_recv", "packets_sent", "packets_recv"],
                "metrics_collection_interval": 10,
                "resources": ["*"]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# ==============================================================================
# GAMING-SPECIFIC TOOLS
# ==============================================================================

# Install tools for gaming workload debugging
yum install -y \
    nmap-ncat \
    telnet \
    curl \
    wget \
    jq \
    vim

# Create gaming diagnostics script
cat > /usr/local/bin/gaming-diagnostics.sh << 'EOF'
#!/bin/bash
echo "=== Gaming Node Diagnostics ==="
echo "Node: $(hostname)"
echo "Date: $(date)"
echo ""

echo "=== Network Statistics ==="
ss -tuln | grep -E ":(80|443|3000|8080|8081|9090)"
echo ""

echo "=== CPU Information ==="
lscpu | grep -E "CPU\(s\)|Model name|CPU MHz"
echo ""

echo "=== Memory Usage ==="
free -h
echo ""

echo "=== Disk Usage ==="
df -h
echo ""

echo "=== Top Processes ==="
ps aux --sort=-%cpu | head -10
echo ""

echo "=== Network Connections ==="
netstat -an | grep -E "(ESTABLISHED|LISTEN)" | wc -l
echo ""

echo "=== Kubernetes Pods ==="
kubectl get pods --all-namespaces --field-selector spec.nodeName=$(hostname) 2>/dev/null || echo "kubectl not accessible"
EOF

chmod +x /usr/local/bin/gaming-diagnostics.sh

# ==============================================================================
# FINALIZATION
# ==============================================================================

# Apply all sysctl changes
sysctl -p

# Log successful completion
echo "Gaming node initialization completed successfully at $(date)" >> /var/log/gaming-node-init.log

# Signal completion to CloudFormation/Terraform
/opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource AutoScalingGroup --region ${AWS::Region} 2>/dev/null || true
# Environment Configuration
environment  = "sandbox"
project_name = "iris-streaming"
aws_region   = "eu-west-1"

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
enable_nat_gateway   = true
single_nat_gateway   = false

# EKS Cluster Configuration
cluster_name                         = "iris-streaming-sandbox-eks"
cluster_version                      = "1.28"
cluster_endpoint_public_access       = true
cluster_endpoint_private_access      = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] # Restrict this in production
enable_cluster_logging               = true
cluster_log_types                    = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

# Node Groups Configuration
node_groups = {
  general = {
    desired_size   = 2
    min_size       = 1
    max_size       = 4
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 50
    labels = {
      role = "general"
    }
    taints = []
  }
  # kafka = {
  #   desired_size   = 3
  #   min_size       = 3
  #   max_size       = 6
  #   instance_types = ["t3.large"]
  #   capacity_type  = "ON_DEMAND"
  #   disk_size      = 100
  #   labels = {
  #     role = "kafka"
  #   }
  #   taints = [
  #     {
  #       key    = "workload"
  #       value  = "kafka"
  #       effect = "NoSchedule"
  #     }
  #   ]
  # }
}

# Add-ons
enable_aws_load_balancer_controller = true
enable_ebs_csi_driver               = true
enable_efs_csi_driver               = false

# Kafka Configuration (if using MSK)
enable_kafka         = false
kafka_version        = "3.5.1"
kafka_broker_count   = 3
kafka_instance_type  = "kafka.m5.large"

# Tags
common_tags = {
  Environment = "sandbox"
  Project     = "iris-streaming"
  ManagedBy   = "Terraform"
  Team        = "Platform"
}

additional_tags = {}

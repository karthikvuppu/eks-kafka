# EKS Infrastructure - Iris Streaming Sandbox

This directory contains Terraform configuration for deploying an Amazon EKS cluster with supporting infrastructure for the Iris Streaming project.

## Architecture Overview

This Terraform configuration creates:
- **VPC** with public and private subnets across multiple availability zones
- **EKS Cluster** with configurable Kubernetes version
- **EKS Node Groups** with flexible configuration
- **IAM Roles and Policies** for EKS cluster and node groups
- **Security Groups** for cluster and node communication
- **NAT Gateways** for private subnet internet access
- **EKS Add-ons**: VPC CNI, CoreDNS, kube-proxy, EBS CSI Driver (optional)
- **AWS Load Balancer Controller** IAM role (optional)

## Directory Structure

```
iris-streaming-sandbox/
├── environments/
│   └── streaming.tfvars    # Environment-specific variables
├── vars/
│   └── backend.hcl         # Backend configuration
├── eks.tf                  # EKS cluster and node groups
├── iam.tf                  # IAM roles and policies
├── vpc.tf                  # VPC and networking resources
├── variables.tf            # Variable definitions
├── outputs.tf              # Output values
├── provider.tf             # Provider configuration
├── kubeconfig.tpl          # Kubeconfig template
└── README.md              # This file
```

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0
3. S3 bucket for Terraform state (update in `vars/backend.hcl`)
4. DynamoDB table for state locking (update in `vars/backend.hcl`)

## Configuration

### 1. Update Backend Configuration

Edit `vars/backend.hcl` with your S3 bucket and DynamoDB table:

```hcl
bucket         = "your-terraform-state-bucket"
key            = "iris-streaming/sandbox/terraform.tfstate"
region         = "eu-west-1"
encrypt        = true
dynamodb_table = "terraform-state-lock"
```

### 2. Customize Environment Variables

Edit `environments/streaming.tfvars` to customize your deployment:

```hcl
# Core Configuration
environment  = "sandbox"
project_name = "iris-streaming"
aws_region   = "eu-west-1"

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

# EKS Configuration
cluster_name    = "iris-streaming-sandbox-eks"
cluster_version = "1.28"

# Node Groups
node_groups = {
  general = {
    desired_size   = 2
    min_size       = 1
    max_size       = 4
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 50
    labels         = { role = "general" }
    taints         = []
  }
}
```

## Deployment

### Initialize Terraform

```bash
terraform init -backend-config=vars/backend.hcl -upgrade
```

### Validate Configuration

```bash
terraform validate
```

### Plan Deployment

```bash
terraform plan -var-file=environments/streaming.tfvars
```

### Apply Configuration

```bash
terraform apply -var-file=environments/streaming.tfvars
```

## Accessing the Cluster

After deployment, configure kubectl:

```bash
aws eks update-kubeconfig --name iris-streaming-sandbox-eks --region eu-west-1
```

Verify access:

```bash
kubectl get nodes
kubectl get pods -A
```

## Customization Options

### Adding Node Groups

Add additional node groups in `environments/streaming.tfvars`:

```hcl
node_groups = {
  general = { ... }
  kafka = {
    desired_size   = 3
    min_size       = 3
    max_size       = 6
    instance_types = ["t3.large"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 100
    labels = {
      role = "kafka"
    }
    taints = [
      {
        key    = "workload"
        value  = "kafka"
        effect = "NoSchedule"
      }
    ]
  }
}
```

### Enabling Additional Features

```hcl
# Enable EBS CSI Driver
enable_ebs_csi_driver = true

# Enable AWS Load Balancer Controller
enable_aws_load_balancer_controller = true

# Enable EFS CSI Driver
enable_efs_csi_driver = true
```

## Resource Naming Convention

Resources follow the naming pattern: `{project_name}-{environment}-{resource_type}`

Example: `iris-streaming-sandbox-eks-cluster`

## Security Considerations

1. **Restrict API Access**: Update `cluster_endpoint_public_access_cidrs` to restrict access
2. **Enable Encryption**: All resources use encryption at rest where applicable
3. **IAM Roles**: Follow principle of least privilege
4. **Network Isolation**: Private subnets for worker nodes
5. **Logging**: Enable CloudWatch logging for audit trails

## Outputs

After deployment, Terraform provides:
- VPC and subnet IDs
- EKS cluster endpoint and certificate
- Node group IDs and ARNs
- IAM role ARNs
- Kubeconfig for cluster access

View outputs:

```bash
terraform output
```

## CI/CD Integration

This configuration is integrated with GitLab CI/CD. See `.gitlab-ci.yml` in the root directory.

## Cleanup

To destroy all resources:

```bash
terraform destroy -var-file=environments/streaming.tfvars
```

**Warning**: This will delete all resources including the EKS cluster and VPC.

## Troubleshooting

### Issue: Terraform state lock

```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### Issue: Node groups not creating

Check:
1. IAM role permissions
2. Subnet tags for EKS
3. Security group rules

### Issue: Cannot connect to cluster

```bash
# Update kubeconfig
aws eks update-kubeconfig --name <cluster-name> --region <region>

# Verify AWS credentials
aws sts get-caller-identity
```

## Additional Resources

- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)

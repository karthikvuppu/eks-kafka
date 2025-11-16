# EKS Infrastructure for Kafka/Streaming Workloads

This repository contains generalized Terraform infrastructure code for deploying Amazon EKS clusters with supporting AWS resources. The infrastructure is designed to support Kafka and streaming workloads but can be adapted for any Kubernetes-based applications.

## Repository Structure

```
.
├── iris-streaming-sandbox/        # Sandbox environment
│   ├── environments/
│   │   └── streaming.tfvars      # Environment-specific variables
│   ├── vars/
│   │   └── backend.hcl           # Backend configuration
│   ├── eks.tf                    # EKS cluster configuration
│   ├── iam.tf                    # IAM roles and policies
│   ├── vpc.tf                    # VPC and networking
│   ├── variables.tf              # Variable definitions
│   ├── outputs.tf                # Output values
│   ├── provider.tf               # Terraform providers
│   └── README.md                 # Environment documentation
├── .gitlab-ci.yml                # CI/CD pipeline
├── .gitignore                    # Git ignore rules
└── README.md                     # This file
```

## Features

### Networking
- Multi-AZ VPC with public and private subnets
- Internet Gateway for public subnets
- NAT Gateways for private subnet internet access
- Configurable CIDR blocks
- Automatic subnet tagging for EKS

### EKS Cluster
- Configurable Kubernetes version
- Public and/or private API endpoint access
- Cluster logging to CloudWatch
- OIDC provider for IAM roles for service accounts (IRSA)
- Security groups with proper ingress/egress rules

### Node Groups
- Multiple node group support with different configurations
- Configurable instance types and capacity (ON_DEMAND/SPOT)
- Auto-scaling groups
- Custom labels and taints
- Managed node group lifecycle

### IAM & Security
- EKS cluster IAM role with required policies
- Node group IAM role with ECR, CNI, and worker node policies
- EBS CSI driver IAM role with IRSA
- AWS Load Balancer Controller IAM role with IRSA
- Principle of least privilege

### Add-ons
- VPC CNI
- CoreDNS
- kube-proxy
- EBS CSI Driver (optional)
- AWS Load Balancer Controller IAM setup (optional)
- EFS CSI Driver (optional)

## Getting Started

### Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **AWS CLI** configured with credentials
4. **S3 Bucket** for Terraform state storage
5. **DynamoDB Table** for state locking

### Quick Start

1. **Clone the repository**

```bash
git clone <repository-url>
cd eks-kafka
```

2. **Configure backend storage**

Edit `iris-streaming-sandbox/vars/backend.hcl`:

```hcl
bucket         = "your-terraform-state-bucket"
key            = "iris-streaming/sandbox/terraform.tfstate"
region         = "eu-west-1"
encrypt        = true
dynamodb_table = "terraform-state-lock"
```

3. **Customize variables**

Edit `iris-streaming-sandbox/environments/streaming.tfvars` with your desired configuration.

4. **Deploy using Terraform**

```bash
cd iris-streaming-sandbox
terraform init -backend-config=vars/backend.hcl
terraform plan -var-file=environments/streaming.tfvars
terraform apply -var-file=environments/streaming.tfvars
```

5. **Configure kubectl**

```bash
aws eks update-kubeconfig --name <cluster-name> --region <region>
kubectl get nodes
```

## Creating Additional Environments

To create a new environment (e.g., dev, prod):

1. **Copy the environment directory**

```bash
cp -r iris-streaming-sandbox iris-streaming-dev
```

2. **Update configuration files**

- Edit `vars/backend.hcl` with new state file path
- Edit `environments/streaming.tfvars` with dev-specific values
- Update environment name and cluster name

3. **Update GitLab CI/CD** (optional)

Add new job definitions in `.gitlab-ci.yml` for the new environment.

## Configuration Variables

### Core Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `environment` | Environment name | - |
| `project_name` | Project name for resource naming | - |
| `aws_region` | AWS region | `eu-west-1` |

### VPC Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `private_subnet_cidrs` | Private subnet CIDRs | `["10.0.1.0/24", ...]` |
| `public_subnet_cidrs` | Public subnet CIDRs | `["10.0.101.0/24", ...]` |
| `enable_nat_gateway` | Enable NAT Gateway | `true` |
| `single_nat_gateway` | Use single NAT Gateway | `false` |

### EKS Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `cluster_name` | EKS cluster name | - |
| `cluster_version` | Kubernetes version | `1.28` |
| `cluster_endpoint_public_access` | Enable public API access | `true` |
| `enable_cluster_logging` | Enable CloudWatch logging | `true` |

### Node Group Variables

| Variable | Description | Type |
|----------|-------------|------|
| `node_groups` | Map of node group configurations | `map(object)` |

Example:
```hcl
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

## CI/CD Pipeline

The repository includes a GitLab CI/CD pipeline with the following stages:

1. **Authenticate**: Assume AWS role using OIDC
2. **Validate**: Validate Terraform configuration
3. **Plan**: Generate execution plan
4. **Apply**: Apply changes (manual trigger)

### Pipeline Variables

Set these in GitLab CI/CD settings:

- `AWS_ROLE_ARN_SANDBOX`: IAM role ARN for sandbox environment
- `AWS_ROLE_ARN_DEVTEST`: IAM role ARN for dev/test environment
- `AWS_ROLE_ARN_PRODUCTION`: IAM role ARN for production environment

## Security Best Practices

1. **Network Isolation**
   - Use private subnets for worker nodes
   - Restrict API endpoint access with CIDR blocks
   - Enable VPC flow logs

2. **IAM**
   - Use IRSA for pod-level permissions
   - Follow least privilege principle
   - Regularly rotate credentials

3. **Encryption**
   - Enable encryption at rest for EBS volumes
   - Use encrypted S3 buckets for state
   - Enable secrets encryption in EKS

4. **Monitoring**
   - Enable CloudWatch logging
   - Set up alerts for critical events
   - Use Container Insights

5. **Compliance**
   - Tag all resources appropriately
   - Enable AWS Config rules
   - Regular security audits

## Outputs

The Terraform configuration provides outputs for:

- VPC ID and subnet IDs
- EKS cluster endpoint and ARN
- Node group information
- IAM role ARNs
- OIDC provider ARN
- Kubeconfig for cluster access

## Troubleshooting

### Common Issues

**Issue**: Terraform state lock error
```bash
terraform force-unlock <LOCK_ID>
```

**Issue**: Node groups fail to create
- Check IAM permissions
- Verify subnet tags
- Review security group rules

**Issue**: Cannot access cluster API
- Verify public access CIDR blocks
- Check security group rules
- Ensure AWS credentials are correct

**Issue**: Pods can't pull images from ECR
- Verify node IAM role has ECR permissions
- Check VPC endpoints for private clusters

## Extending the Infrastructure

### Adding Kafka (MSK)

Uncomment and configure Kafka variables in `variables.tf` and add MSK resources.

### Adding Monitoring

Consider adding:
- Prometheus and Grafana using Helm
- CloudWatch Container Insights
- AWS X-Ray for distributed tracing

### Adding Service Mesh

Deploy Istio or AWS App Mesh for:
- Traffic management
- Security policies
- Observability

## Contributing

1. Create a feature branch
2. Make your changes
3. Test in sandbox environment
4. Submit merge request
5. Get approval and merge

## Support

For issues and questions:
- Create an issue in the repository
- Contact the platform team
- Refer to AWS EKS documentation

## License

[Specify your license here]

## Additional Resources

- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS MSK Documentation](https://docs.aws.amazon.com/msk/)

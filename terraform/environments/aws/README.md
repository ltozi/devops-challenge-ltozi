# Terraform Infrastructure as Code

This directory contains the root module for the **AWS (EKS)** environment.

## 🏗️ Architecture

This project uses a "per-environment" root module structure. There are two primary environments, each in its own directory:
- **`environments/local`**: For deploying to a local Minikube cluster.
- **`environments/aws`**: For deploying to a production-like AWS EKS cluster.

Both environments share common logic by calling reusable modules from the `modules/` directory.

### Directory Structure

```
terraform/
├── environments/
│   ├── local/
│   │   ├── main.tf                # Root module for local (Minikube)
│   │   ├── terraform-local.tfvars # Variables for local
│   │   └── tf-local.sh            # Helper script for local deployment
│   └── aws/
│       ├── main.tf                # Root module for AWS (EKS)
│       ├── terraform-aws.tfvars   # Variables for AWS
│       └── variables.tf           # Variables definitions (for the AWS root module)
└── modules/
    ├── infra-stack/             # SHARED: Deploys k8s resources
    ├── networking/              # AWS VPC module
    ├── eks/                     # EKS cluster module
    ├── k8s-resources/           # App + MongoDB deployments
    └── monitoring/              # Prometheus + Grafana
```

### How It Works

- The `environments/aws/main.tf` file provisions the AWS-specific infrastructure (VPC, EKS cluster) and then calls the `infra-stack` module to deploy the Kubernetes resources onto the EKS cluster.
- State is managed independently for each environment. For `aws`, state is recommended to be stored in an S3 backend with DynamoDB locking.

## 📋 Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.6.0
- [AWS CLI](https://aws.amazon.com/cli/) >= 2.0
- AWS credentials configured with appropriate IAM permissions for EKS, VPC, EC2, IAM.
- Docker

## 🚀 Quick Start: AWS Deployment (EKS)

1. **Configure AWS credentials**:
   ```bash
   aws configure
   # Or use AWS_PROFILE environment variable
   export AWS_PROFILE=your-profile
   ```

2. **Set MongoDB password**:
   You must set the MongoDB root password, either as an environment variable or in a `terraform-aws.tfvars` file (ensure it's gitignored).
   ```bash
   export TF_VAR_mongodb_root_password="strong_production_password"
   ```

3. **Initialize Terraform**:
   (From within the `terraform/environments/aws` directory)
   ```bash
   terraform init
   ```

4. **Plan infrastructure**:
   ```bash
   terraform plan -var-file=terraform-aws.tfvars
   ```

5. **Apply configuration** (⚠️ This creates AWS resources and incurs costs):
   ```bash
   terraform apply -var-file=terraform-aws.tfvars
   # Review carefully and type 'yes' when prompted
   ```

6. **Configure kubectl**:
   After the EKS cluster is created, configure `kubectl` to interact with it:
   ```bash
   aws eks update-kubeconfig --region $(terraform output -raw aws_region) --name $(terraform output -raw eks_cluster_name)
   ```

7. **Build and push Docker image to ECR**:
   First, from the project root, build your Docker image:
   ```bash
   docker build -t tech-challenge-app:latest .
   ```
   Then, get the ECR URL from Terraform outputs (run this from `terraform/environments/aws`):
   ```bash
   ECR_URL=$(terraform output -raw ecr_repository_url)
   ```
   Login to ECR:
   ```bash
   aws ecr get-login-password --region $(terraform output -raw aws_region) | docker login --username AWS --password-stdin $ECR_URL
   ```
   Tag and push your image:
   ```bash
   docker tag tech-challenge-app:latest $ECR_URL:latest
   docker push $ECR_URL:latest
   ```

8. **Update and re-apply** to use ECR image:
   Update `app_image` in `terraform-aws.tfvars` with the ECR URL, then run Terraform apply again:
   ```bash
   terraform apply -var-file=terraform-aws.tfvars
   ```

9. **Get LoadBalancer URL**:
    ```bash
    kubectl get svc tech-challenge-app -n tech-challenge
    # Wait for EXTERNAL-IP (takes 2-3 minutes)
    ```
    For monitoring services, see the instructions from the `terraform apply` output.

## 📊 Terraform State Management

### Current Setup: Local State
State is stored locally in `terraform.tfstate`. **This is NOT recommended for production.**

### Best Practice: Remote State (Production)

For team collaboration and production use, configure remote state backend. The `main.tf` in this directory contains a commented-out `backend "s3"` block. Follow these steps:

#### Step 1: Create S3 Backend (Run once)

```bash
# Create S3 bucket for state
aws s3api create-bucket \
  --bucket tech-challenge-terraform-state-$(aws sts get-caller-identity --query Account --output text) \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket tech-challenge-terraform-state-$(aws sts get-caller-identity --query Account --output text) \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket tech-challenge-terraform-state-$(aws sts get-caller-identity --query Account --output text) \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

#### Step 2: Enable Backend in main.tf

Uncomment the backend configuration in `main.tf` and update `bucket` with your S3 bucket name:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket-aws" # <--- UPDATE THIS
    key            = "tech-challenge/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

#### Step 3: Migrate State

```bash
terraform init -migrate-state
```

## 🧹 Cleanup

To destroy the AWS resources created:
(From within the `terraform/environments/aws` directory)
```bash
terraform destroy -var-file=terraform-aws.tfvars
# Review carefully and type 'yes' when prompted
```
⚠️ **Important**: This deletes all AWS resources and may take 10-15 minutes.

## 🐛 Troubleshooting

### "Error creating EKS Cluster: InvalidParameterException"

**Solution**: Check AWS credentials and IAM permissions:
```bash
aws sts get-caller-identity
aws iam get-user
```

### "Error: Kubernetes cluster unreachable"

**Solution**:
```bash
aws eks update-kubeconfig --region $(terraform output -raw aws_region) --name $(terraform output -raw eks_cluster_name)
kubectl cluster-info
```

### Application pods not starting

**Check image availability**:
```bash
# For AWS:
kubectl describe pod -n tech-challenge -l app=tech-challenge-app
```

## 💰 Cost Estimation (AWS)

Approximate monthly costs in us-east-1:
- EKS Cluster: $73/month
- t3.medium nodes (2x): ~$60/month
- NAT Gateway: ~$33/month
- EBS volumes: ~$1-2/month
- LoadBalancer: ~$16/month

**Total: ~$183/month** (prices may vary)

**Cost Optimization Tips**:
- Use `single_nat_gateway = true` for non-prod (~$33 savings)
- Use SPOT instances for nodes (~30% savings)
- Delete resources when not in use

## 📚 Further Reading

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

## 🤝 Contributing

When modifying Terraform code:
1. Run `terraform fmt` to format code
2. Run `terraform validate` to validate syntax
3. Test in local environment first
4. Document any new variables or modules
5. Update this README if needed

## 📄 License

Part of the tech-challenge DevOps project.

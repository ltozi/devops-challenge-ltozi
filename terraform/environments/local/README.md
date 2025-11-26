# Terraform Infrastructure as Code

This directory contains the root module for the **local (Minikube)** environment.

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
│       └── terraform-aws.tfvars   # Variables for AWS
└── modules/
    ├── infra-stack/             # SHARED: Deploys k8s resources
    ├── networking/              # AWS VPC module
    ├── eks/                     # EKS cluster module
    ├── k8s-resources/           # App + MongoDB deployments
    └── monitoring/              # Prometheus + Grafana
```

### How It Works

- The `environments/local/main.tf` file defines the providers for Minikube and calls the `infra-stack` module to deploy the Kubernetes resources.
- State is managed independently for each environment. For `local`, state is stored in the `terraform.tfstate` file within this directory.

## 📋 Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.6.0
- [Minikube](https://minikube.sigs.k8s.io/docs/start/) >= 1.32.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/) >= 1.28.0
- Docker

## 🚀 Quick Start: Local Deployment (Minikube)

The local deployment process is automated with a helper script.

1. **Start Minikube**:
   ```bash
   minikube start --cpus=4 --memory=8192
   ```

2. **Build and load Docker image**:
   (From the root of the project)
   ```bash
   docker build -t tech-challenge-app:latest .
   minikube image load tech-challenge-app:latest
   ```

3. **Run the deployment script**:
   The `tf-local.sh` script dynamically extracts Minikube connection details and exports them as `TF_VAR_*` environment variables, then runs Terraform commands.
   
   First, initialize Terraform:
   ```bash
   terraform init
   ```

   Then, use the script to plan or apply:
   ```bash
   # Plan the deployment (extracts Minikube config dynamically)
   ./tf-local.sh plan

   # Apply the configuration
   ./tf-local.sh apply
   ```
   
   **How it works:**
   - The script reads your current Minikube cluster configuration
   - Extracts API server host, port, and certificates
   - Exports them as environment variables (`TF_VAR_minikube_host`, `TF_VAR_minikube_port`, etc.)
   - Runs terraform with `-var-file=terraform-local.tfvars`
   
   This ensures the connection details are always up-to-date with your current Minikube cluster.

4. **Access the application**:
   ```bash
   minikube service tech-challenge-app -n tech-challenge --url
   ```
   For monitoring services, see the instructions from the `terraform apply` output.

## 🧹 Cleanup

To destroy the resources created in your Minikube cluster, use the script:
```bash
./tf-local.sh destroy
```

## 🐛 Troubleshooting

### "Error: Kubernetes cluster unreachable" or "Error: couldn't get current server API group list"

**Solution**: Ensure Minikube is running and your kubectl context is correct.
```bash
minikube status
kubectl config use-context minikube
kubectl cluster-info
```
The `tf-local.sh` script should handle connecting to the cluster automatically. If it fails, these commands can help diagnose the issue.

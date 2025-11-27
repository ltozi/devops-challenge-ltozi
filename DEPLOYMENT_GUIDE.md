# Deployment Guide

Complete guide for deploying the tech-challenge application locally and on AWS.

## Prerequisites

### Required Tools
- **Docker** (v20+) - For building and running containers
- **Docker Compose** (v2+) - For local orchestration
- **kubectl** (v1.28+) - Kubernetes CLI
- **Minikube** (v1.32+) - Local Kubernetes cluster
- **Terraform** (v1.6+) - Infrastructure as Code
- **AWS CLI** (v2+) - AWS command line interface
- **pnpm** (v8+) - Package manager (optional for local development)

### Installation Commands (macOS)

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Docker Desktop
brew install --cask docker

# Install kubectl
brew install kubectl

# Install Minikube
brew install minikube

# Install Terraform
brew install terraform

# Install AWS CLI
brew install awscli

# Install pnpm (optional)
brew install pnpm
```

## Local Development with Docker Compose

### Quick Start

1. **Clone the repository** (if not already done):
   ```bash
   cd /Users/luigi/works/projects/devops-stack/devops-tech-challenge
   ```

2. **Build the Docker image**:
   ```bash
   docker build -t tech-challenge-app:latest .
   ```

3. **Start the application**:
   ```bash
   docker compose up -d
   ```

4. **Verify the application**:
   ```bash
   curl http://localhost:3001
   ```

5. **Check logs**:
   ```bash
   docker compose logs -f app
   docker compose logs -f mongodb
   ```

6. **Stop the application**:
   ```bash
   docker compose down
   # To remove volumes as well:
   docker compose down -v
   ```

### Environment Variables

Create or modify `.env` file (already created from `.env.example`):

```env
PORT=3000
NODE_ENV=production
MONGODB_URI=mongodb://root:example_password@mongodb:27017/tech_challenge?authSource=admin
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD=example_password
MONGO_INITDB_DATABASE=tech_challenge
```

**Important:** Change passwords before deploying to production!

## Local Kubernetes Deployment (Minikube)

### Setup Minikube


3. **Wait for pods to be ready**:
   ```bash
   kubectl wait --for=condition=ready pod -l app=mongodb -n tech-challenge --timeout=180s
   kubectl wait --for=condition=ready pod -l app=tech-challenge-app -n tech-challenge --timeout=180s
   ```

4. **Access the application**:
   ```bash
   # Get the service URL
   minikube service tech-challenge-app -n tech-challenge --url
   
   # Or open in browser
   minikube service tech-challenge-app -n tech-challenge
   ```

5. **Verify deployment**:
   ```bash
   kubectl get all -n tech-challenge
   kubectl logs -n tech-challenge -l app=tech-challenge-app
   ```

### Update Application Image

```bash
# Rebuild image
docker build -t tech-challenge-app:latest .

# Load to Minikube
minikube image load tech-challenge-app:latest

# Restart deployment
kubectl rollout restart deployment/tech-challenge-app -n tech-challenge
```

### Cleanup Minikube Deployment

```bash
# Delete all resources
kubectl delete namespace tech-challenge

# Or stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete
```

## AWS EKS Deployment

### Prerequisites

1. **Configure AWS CLI**:
   ```bash
   aws configure
   # Enter: AWS Access Key ID, Secret Access Key, Region (e.g., us-east-1), Output format (json)
   ```

2. **Verify AWS credentials**:
   ```bash
   aws sts get-caller-identity
   ```

### Deploy Infrastructure with Terraform

**Note:** Terraform configurations will be provided in the `terraform/` directory (to be created).

1. **Navigate to Terraform directory**:
   ```bash
   cd terraform/environments/aws
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Review the plan**:
   ```bash
   terraform plan
   ```

4. **Apply infrastructure** (IMPORTANT: Never use --auto-approve):
   ```bash
   terraform apply
   # Review the plan and type 'yes' when prompted
   ```

5. **Configure kubectl for EKS**:
   ```bash
   aws eks update-kubeconfig --region <region> --name <cluster-name>
   ```

### Push Image to ECR

1. **Create ECR repository** (if not created by Terraform):
   ```bash
   aws ecr create-repository --repository-name tech-challenge-app --region <region>
   ```

2. **Authenticate Docker to ECR**:
   ```bash
   aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com
   ```

3. **Tag and push image**:
   ```bash
   docker tag tech-challenge-app:latest <account-id>.dkr.ecr.<region>.amazonaws.com/tech-challenge-app:latest
   docker push <account-id>.dkr.ecr.<region>.amazonaws.com/tech-challenge-app:latest
   ```

4. **Update deployment image reference**:
   Edit `k8s/base/app/deployment.yaml` and change:
   ```yaml
   image: <account-id>.dkr.ecr.<region>.amazonaws.com/tech-challenge-app:latest
   ```

### Deploy Application to EKS

1. **Create secrets with production values**:
   ```bash
   kubectl create secret generic mongodb-secret \
     --from-literal=mongodb-root-username=<prod-username> \
     --from-literal=mongodb-root-password=<prod-password> \
     --namespace=tech-challenge \
     --dry-run=client -o yaml | kubectl apply -f -
   
   kubectl create secret generic app-secret \
     --from-literal=MONGODB_URI='mongodb://<prod-username>:<prod-password>@mongodb:27017/tech_challenge?authSource=admin' \
     --namespace=tech-challenge \
     --dry-run=client -o yaml | kubectl apply -f -
   ```

2. **Deploy resources**:
   ```bash
   kubectl apply -f k8s/base/namespace.yaml
   kubectl apply -f k8s/base/mongodb/
   kubectl apply -f k8s/base/app/
   kubectl apply -f k8s/overlays/aws/service-loadbalancer.yaml
   ```

3. **Get LoadBalancer URL**:
   ```bash
   kubectl get svc tech-challenge-app -n tech-challenge
   # Wait for EXTERNAL-IP to be assigned (may take 2-3 minutes)
   ```

4. **Test the application**:
   ```bash
   curl http://<EXTERNAL-IP>/
   ```

### Cleanup AWS Resources

1. **Delete Kubernetes resources**:
   ```bash
   kubectl delete namespace tech-challenge
   ```

2. **Destroy Terraform infrastructure**:
   ```bash
   cd terraform/environments/aws
   terraform destroy
   # Review the plan and type 'yes' when prompted
   ```

## CI/CD Pipeline

The GitHub Actions pipeline is configured in `.github/workflows/ci-cd.yml`.

### Pipeline Stages

1. **Build** - Builds Docker image
2. **Security Scan** - Scans image with Trivy
3. **Test** - Runs unit and E2E tests
4. **Integration Test** - Tests with Docker Compose
5. **Push** - Pushes to Docker Hub (main branch only)

### Required GitHub Secrets

Configure these secrets in your GitHub repository:

- `DOCKER_USERNAME` - Docker Hub username
- `DOCKER_PASSWORD` - Docker Hub password/token

### Triggering the Pipeline

```bash
# Push to main branch
git add .
git commit -m "Deploy application"
git push origin main
```

## Monitoring

### Health Checks

**Application health**:
```bash
curl http://localhost:3001/
```

**MongoDB health**:
```bash
docker exec tech-challenge-mongodb mongosh --eval "db.adminCommand('ping')"
```

**Kubernetes health**:
```bash
kubectl get pods -n tech-challenge
kubectl describe pod <pod-name> -n tech-challenge
kubectl logs <pod-name> -n tech-challenge
```

### Resource Usage

```bash
# Docker Compose
docker stats

# Kubernetes
kubectl top pods -n tech-challenge
kubectl top nodes
```

## Troubleshooting

### Docker Compose Issues

**Port already in use**:
```bash
# Find process using port 3001
lsof -ti:3001
# Change port in docker-compose.yml or stop the process
```

**Container fails to start**:
```bash
docker compose logs app
docker compose logs mongodb
```

### Kubernetes Issues

**Pods not starting**:
```bash
kubectl describe pod <pod-name> -n tech-challenge
kubectl logs <pod-name> -n tech-challenge
```

**Image pull errors**:
```bash
# For Minikube, ensure image is loaded:
minikube image ls | grep tech-challenge
minikube image load tech-challenge-app:latest

# For EKS, verify ECR authentication:
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com
```

**MongoDB connection issues**:
```bash
# Check MongoDB is running
kubectl get pods -n tech-challenge -l app=mongodb

# Check service
kubectl get svc mongodb -n tech-challenge

# Test connection from app pod
kubectl exec -it <app-pod-name> -n tech-challenge -- sh
# Inside pod:
curl mongodb:27017
```

## Security Best Practices

1. **Change default passwords** in production
2. **Use Kubernetes Secrets** for sensitive data
3. **Enable RBAC** in Kubernetes
4. **Use Network Policies** to restrict pod communication
5. **Regularly scan images** for vulnerabilities
6. **Keep dependencies updated**
7. **Use TLS/SSL** for external communications
8. **Implement proper logging** and monitoring
9. **Backup MongoDB data** regularly
10. **Follow principle of least privilege**

## Next Steps

1. Set up monitoring with Prometheus/Grafana
2. Configure alerting
3. Implement backup strategy
4. Set up log aggregation (ELK stack)
5. Configure auto-scaling
6. Implement blue-green or canary deployments
7. Set up disaster recovery plan
8. Document runbooks for common operations

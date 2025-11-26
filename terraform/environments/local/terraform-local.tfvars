# Local Environment Configuration (Minikube)
environment  = "local"
project_name = "tech-challenge"
k8s_version  = "1.28"

# Application Configuration
app_image    = "tech-challenge-app:latest"
app_replicas = 1 # Single replica for local testing

# MongoDB Configuration
mongodb_storage_size  = "5Gi" # Smaller for local
mongodb_root_username = "root"

# Monitoring Configuration
enable_monitoring       = true # Set to true to enable Prometheus and Grafana
prometheus_storage_size = "10Gi"
grafana_storage_size    = "5Gi"

# Minikube connection variables are provided dynamically via tf-local.sh script
# which exports them as TF_VAR_* environment variables

# Kubernetes Resources Module (Both local and AWS)
module "k8s_resources" {
  source = "../k8s-resources"

  environment          = var.environment
  project_name         = var.project_name
  app_image            = var.app_image
  app_replicas         = var.app_replicas
  mongodb_storage_size = var.mongodb_storage_size
  app_service_type     = var.app_service_type

  # Secrets
  mongodb_root_username = var.mongodb_root_username
}

# Monitoring Module (Both local and AWS)
module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "../monitoring"

  app_namespace           = module.k8s_resources.namespace
  prometheus_storage_size = var.prometheus_storage_size
  grafana_storage_size    = var.grafana_storage_size
  service_type            = var.app_service_type

  # MongoDB connection URI for exporter
  mongodb_uri = "mongodb://${var.mongodb_root_username}:${module.k8s_resources.mongodb_admin_password}@mongodb-service.${module.k8s_resources.namespace}.svc.cluster.local:27017"

  depends_on = [
    module.k8s_resources
  ]
}

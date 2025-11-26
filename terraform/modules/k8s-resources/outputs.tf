output "namespace" {
  description = "Kubernetes namespace"
  value       = kubernetes_namespace.main.metadata[0].name
}

output "app_service_name" {
  description = "Application service name"
  value       = kubernetes_service.app.metadata[0].name
}

output "app_service_type" {
  description = "Application service type"
  value       = kubernetes_service.app.spec[0].type
}

output "mongodb_service_name" {
  description = "MongoDB service name"
  value       = kubernetes_service.mongodb.metadata[0].name
}

output "mongodb_admin_password" {
  description = "MongoDB service name"
  value       = random_password.mongodb_root_password.result
}
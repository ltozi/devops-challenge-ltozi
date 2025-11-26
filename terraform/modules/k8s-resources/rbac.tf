# RBAC Configuration
# Implements least-privilege service accounts for application and MongoDB

# Application Service Account
resource "kubernetes_service_account" "app" {
  metadata {
    name      = "${local.app_name}-sa"
    namespace = kubernetes_namespace.main.metadata[0].name
    labels = {
      app = local.app_name
    }
  }

  automount_service_account_token = true
}

# MongoDB Service Account
resource "kubernetes_service_account" "mongodb" {
  metadata {
    name      = "${local.mongo_name}-sa"
    namespace = kubernetes_namespace.main.metadata[0].name
    labels = {
      app = local.mongo_name
    }
  }

  automount_service_account_token = false # MongoDB doesn't need K8s API access
}

# Application Role
# Minimal permissions - app doesn't need K8s API access typically
# But we define it in case future features need it
resource "kubernetes_role" "app" {
  metadata {
    name      = "${local.app_name}-role"
    namespace = kubernetes_namespace.main.metadata[0].name
  }

  # Minimal rule - allows getting the service account itself
  # This is effectively a no-op but satisfies Terraform's requirement for at least 1 rule
  rule {
    api_groups     = [""]
    resources      = ["serviceaccounts"]
    resource_names = [kubernetes_service_account.app.metadata[0].name]
    verbs          = ["get"]
  }
}

# Application RoleBinding
resource "kubernetes_role_binding" "app" {
  metadata {
    name      = "${local.app_name}-rolebinding"
    namespace = kubernetes_namespace.main.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.app.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.app.metadata[0].name
    namespace = kubernetes_namespace.main.metadata[0].name
  }
}

# Read-only Role for Monitoring/Debugging
# Can be bound to monitoring service accounts or debugging users
resource "kubernetes_role" "readonly" {
  metadata {
    name      = "readonly-role"
    namespace = kubernetes_namespace.main.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "configmaps"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/log"]
    verbs      = ["get", "list"]
  }
}

# Pod Security Standards
# Label namespace to enforce pod security standards
resource "kubernetes_labels" "namespace_pod_security" {
  api_version = "v1"
  kind        = "Namespace"
  metadata {
    name = kubernetes_namespace.main.metadata[0].name
  }

  labels = {
    "pod-security.kubernetes.io/enforce" = "baseline"   # Enforce baseline policy
    "pod-security.kubernetes.io/audit"   = "restricted" # Audit against restricted policy
    "pod-security.kubernetes.io/warn"    = "restricted" # Warn about restricted violations
  }

  depends_on = [kubernetes_namespace.main]
}

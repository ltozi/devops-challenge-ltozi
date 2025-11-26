resource "random_password" "mongodb_root_password" {
  length           = 16
  special          = false # Explicitly disable the inclusion of special characters
  override_special = false # Ensures 'special' setting is not overridden by other arguments

  # Recommended for stronger security: Ensure a mix of character types
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1

  # Optional: Keep it simple if you are fine with the default
  # min_length_upper, min_length_lower, and min_length_numeric
  # default to 0 if 'special' is false, but setting them > 0 is best practice.
}


locals {
  namespace  = "tech-challenge"
  app_name   = "tech-challenge-app"
  mongo_name = "mongodb"
}

# Namespace
resource "kubernetes_namespace" "main" {
  metadata {
    name = local.namespace
    labels = {
      name        = local.namespace
      environment = var.environment
    }
  }
}

# MongoDB Secret
resource "kubernetes_secret" "mongodb" {
  metadata {
    name      = "mongodb-secret"
    namespace = kubernetes_namespace.main.metadata[0].name
  }

  data = {
    mongodb-root-username = var.mongodb_root_username
    mongodb-root-password = random_password.mongodb_root_password.result
  }

  type = "Opaque"
}

# MongoDB Init Script ConfigMap
resource "kubernetes_config_map" "mongodb_init" {
  metadata {
    name      = "mongodb-init-script"
    namespace = kubernetes_namespace.main.metadata[0].name
  }

  data = {
    "mongo-init.js" = file("${path.root}/../../../init_scripts/mongo-init.js")
  }
}

# MongoDB StatefulSet
resource "kubernetes_stateful_set" "mongodb" {
  metadata {
    name      = local.mongo_name
    namespace = kubernetes_namespace.main.metadata[0].name
    labels = {
      app = local.mongo_name
    }
  }

  spec {
    service_name = local.mongo_name
    replicas     = 1

    selector {
      match_labels = {
        app = local.mongo_name
      }
    }

    template {
      metadata {
        labels = {
          app = local.mongo_name
        }
      }

      spec {
        service_account_name = kubernetes_service_account.mongodb.metadata[0].name

        container {
          name  = local.mongo_name
          image = "mongo:7"

          port {
            container_port = 27017
            name           = "mongodb"
          }

          env {
            name = "MONGO_INITDB_ROOT_USERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mongodb.metadata[0].name
                key  = "mongodb-root-username"
              }
            }
          }

          env {
            name = "MONGO_INITDB_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mongodb.metadata[0].name
                key  = "mongodb-root-password"
              }
            }
          }

          env {
            name  = "MONGO_INITDB_DATABASE"
            value = "tech_challenge"
          }

          resources {
            requests = {
              memory = "512Mi"
              cpu    = "250m"
            }
            limits = {
              memory = "1Gi"
              cpu    = "500m"
            }
          }

          liveness_probe {
            exec {
              command = ["mongosh", "--eval", "db.adminCommand('ping')"]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            exec {
              command = ["mongosh", "--eval", "db.adminCommand('ping')"]
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          volume_mount {
            name       = "mongodb-data"
            mount_path = "/data/db"
          }

          volume_mount {
            name       = "init-script"
            mount_path = "/docker-entrypoint-initdb.d"
          }
        }

        volume {
          name = "init-script"
          config_map {
            name = kubernetes_config_map.mongodb_init.metadata[0].name
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "mongodb-data"
      }

      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = var.mongodb_storage_size
          }
        }
      }
    }
  }
}

# MongoDB Service
resource "kubernetes_service" "mongodb" {
  metadata {
    name      = local.mongo_name
    namespace = kubernetes_namespace.main.metadata[0].name
    labels = {
      app = local.mongo_name
    }
  }

  spec {
    type = "ClusterIP"

    port {
      port        = 27017
      target_port = 27017
      protocol    = "TCP"
      name        = "mongodb"
    }

    selector = {
      app = local.mongo_name
    }
  }
}

# Application ConfigMap
resource "kubernetes_config_map" "app" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.main.metadata[0].name
  }

  data = {
    PORT     = "3000"
    NODE_ENV = "production"
  }
}

# Application Secret
resource "kubernetes_secret" "app" {
  metadata {
    name      = "app-secret"
    namespace = kubernetes_namespace.main.metadata[0].name
  }

  data = {
    MONGODB_URI = "mongodb://${var.mongodb_root_username}:${random_password.mongodb_root_password.result}@${local.mongo_name}:27017/tech_challenge?authSource=admin"
  }

  type = "Opaque"
}

# Application Deployment
resource "kubernetes_deployment" "app" {
  metadata {
    name      = local.app_name
    namespace = kubernetes_namespace.main.metadata[0].name
    labels = {
      app = local.app_name
    }
  }

  spec {
    replicas = var.app_replicas

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = 1
        max_unavailable = 0
      }
    }

    selector {
      match_labels = {
        app = local.app_name
      }
    }

    template {
      metadata {
        labels = {
          app = local.app_name
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "3000"
          "prometheus.io/path"   = "/metrics"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.app.metadata[0].name

        security_context {
          run_as_non_root = true
          run_as_user     = 1001
          fs_group        = 1001
        }

        container {
          name              = "app"
          image             = var.app_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 3000
            name           = "http"
            protocol       = "TCP"
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.app.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.app.metadata[0].name
            }
          }

          resources {
            requests = {
              memory = "256Mi"
              cpu    = "250m"
            }
            limits = {
              memory = "512Mi"
              cpu    = "500m"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 3000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 3000
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = false
            run_as_non_root            = true
            run_as_user                = 1001
            capabilities {
              drop = ["ALL"]
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_stateful_set.mongodb
  ]
}

# Application Service
resource "kubernetes_service" "app" {
  metadata {
    name      = local.app_name
    namespace = kubernetes_namespace.main.metadata[0].name
    labels = {
      app = local.app_name
    }
    annotations = var.app_service_type == "LoadBalancer" ? {
      "service.beta.kubernetes.io/aws-load-balancer-type"                              = "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
    } : {}
  }

  spec {
    type = var.app_service_type

    port {
      port        = 80
      target_port = 3000
      protocol    = "TCP"
      name        = "http"
      node_port   = var.app_service_type == "NodePort" ? 30080 : null
    }

    selector = {
      app = local.app_name
    }
  }

  depends_on = [
    kubernetes_deployment.app
  ]
}

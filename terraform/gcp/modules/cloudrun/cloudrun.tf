# Cloud Run Service for PostgreSQL
resource "google_cloud_run_service" "postgres" {
  name     = "ecc-project-postgres"
  location = var.region

  metadata {
    annotations = {
      "run.googleapis.com/ingress"                 = "internal"
      "run.googleapis.com/enable-tcp-health-check" = "true"
    }
  }

  template {
    metadata {
      annotations = {
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.name
        "run.googleapis.com/vpc-access-egress"    = "all-traffic"
      }
    }

    spec {
      containers {
        image = "postgres:16"
        ports {
          container_port = 5432
        }
        env {
          name  = "POSTGRES_USER"
          value = var.postgres_user
        }
        env {
          name  = "POSTGRES_PASSWORD"
          value = var.postgres_password
        }
        env {
          name  = "POSTGRES_DB"
          value = var.postgres_db
        }
        env {
          name  = "POSTGRES_HOST_AUTH_METHOD"
          value = "trust"
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Cloud Run Service for Django
resource "google_cloud_run_service" "django" {
  name     = "ecc-project-django"
  location = var.region

  metadata {
    annotations = {
      "run.googleapis.com/ingress"                 = "internal"
      "run.googleapis.com/enable-tcp-health-check" = "true"
    }
  }

  template {
    metadata {
      annotations = {
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.name
        "run.googleapis.com/vpc-access-egress"    = "all-traffic"
      }
    }

    spec {
      containers {
        image = "gcr.io/google-samples/hello-app:1.0"

        ports {
          container_port = 8000
        }

        env {
          name  = "POSTGRES_USER"
          value = var.postgres_user
        }
        env {
          name  = "POSTGRES_PASSWORD"
          value = var.postgres_password
        }
        env {
          name  = "POSTGRES_DB"
          value = var.postgres_db
        }
        env {
          name  = "POSTGRES_HOST"
          value = "${google_cloud_run_service.postgres.name}-809000347521.${var.region}.run.app"
        }
        env {
          name  = "POSTGRES_PORT"
          value = tostring(var.db_port)
        }
        env {
          name  = "USE_DOCKER"
          value = "yes"
        }
        env {
          name  = "IPYTHONDIR"
          value = "/app/.ipython"
        }

        startup_probe {
          http_get {
            path = "/"
          }
          initial_delay_seconds = 120
          period_seconds        = 30
          failure_threshold     = 3
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# VPC Access Connector for Cloud Run
resource "google_vpc_access_connector" "connector" {
  name          = "ecc-project-connector"
  region        = var.region
  network       = var.vpc_id
  ip_cidr_range = "10.8.0.0/28"
}

# IAM permissions to allow Django to invoke PostgreSQL
resource "google_cloud_run_service_iam_binding" "postgres_invoker" {
  service  = google_cloud_run_service.postgres.name
  location = google_cloud_run_service.postgres.location
  members  = ["allUsers"]
  role     = "roles/run.invoker"
}

# Load Balancer and other configurations remain unchanged
resource "google_compute_global_address" "lb_ip" {
  name = "${var.project_id}-lb-ip"
}

resource "google_compute_global_forwarding_rule" "django_lb" {
  name                  = "${var.project_id}-lb"
  ip_address            = google_compute_global_address.lb_ip.address
  port_range            = "80"
  target                = google_compute_target_http_proxy.django_proxy.id
}

resource "google_compute_target_http_proxy" "django_proxy" {
  name    = "${var.project_id}-http-proxy"
  url_map = google_compute_url_map.django_urlmap.id
}

resource "google_compute_url_map" "django_urlmap" {
  name            = "${var.project_id}-urlmap"
  default_service = google_compute_backend_service.django_backend.id
}

resource "google_compute_backend_service" "django_backend" {
  name        = "${var.project_id}-backend"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 30

  backend {
    group = google_compute_region_network_endpoint_group.django_neg.id
  }
}

resource "google_compute_region_network_endpoint_group" "django_neg" {
  name                  = "${var.project_id}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = google_cloud_run_service.django.name
  }
}

resource "google_compute_health_check" "django_hc" {
  name               = "${var.project_id}-hc"
  check_interval_sec = 30
  timeout_sec        = 5

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

# IAM permissions to allow Cloud Run to be invoked
resource "google_cloud_run_service_iam_policy" "django_noauth" {
  location = google_cloud_run_service.django.location
  project  = google_cloud_run_service.django.project
  service  = google_cloud_run_service.django.name

  policy_data = data.google_iam_policy.noauth.policy_data
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers"
    ]
  }
}

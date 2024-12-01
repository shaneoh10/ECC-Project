# Cloud Run Service for PostgreSQL
resource "google_cloud_run_service" "postgres" {
  name     = "${var.project_id}-postgres"
  location = var.region

  template {
    spec {
      containers {
        image = "postgres:16"
        ports {
          container_port = tostring(var.db_port)
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
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "1"
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.id
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
  name     = "${var.project_id}-django"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/google-samples/hello-app:1.0"
        ports {
          container_port = tostring(var.db_port)
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
          value = var.postgres_host
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
          initial_delay_seconds = 60
          period_seconds        = 30
          failure_threshold     = 3
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"          = "1"
        "run.googleapis.com/vpc-access-connector"   = google_vpc_access_connector.connector.id
        "run.googleapis.com/vpc-access-egress"      = "private-ranges-only"
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
  name          = "${var.project_id}"
  region        = var.region
  network       = var.vpc_id
  ip_cidr_range = "10.8.0.0/28"
}

# Load Balancer (using Google Cloud Load Balancing)
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

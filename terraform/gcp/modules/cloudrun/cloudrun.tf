# PostgreSQL VM
resource "google_compute_instance" "postgres" {
  name         = "ecc-project-postgres"
  machine_type = "e2-small"
  zone         = "${var.region}-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network    = var.vpc_id
    subnetwork = var.subnet_id
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker

    sudo docker run -d \
      --name postgres \
      -e POSTGRES_USER=${var.postgres_user} \
      -e POSTGRES_PASSWORD=${var.postgres_password} \
      -e POSTGRES_DB=${var.postgres_db} \
      -e POSTGRES_HOST_AUTH_METHOD=md5 \
      -p 5432:5432 \
      postgres:16
  EOF

  service_account {
    scopes = ["cloud-platform"]
  }

  tags = ["postgres"]
}

# Django VM
resource "google_compute_instance" "django" {
  name         = "ecc-project-django"
  machine_type = "e2-small"
  zone         = "${var.region}-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network    = var.vpc_id
    subnetwork = var.subnet_id
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker

    sudo docker run -d \
      --name django \
      -e POSTGRES_USER=${var.postgres_user} \
      -e POSTGRES_PASSWORD=${var.postgres_password} \
      -e POSTGRES_DB=${var.postgres_db} \
      -e POSTGRES_HOST=${google_compute_instance.postgres.network_interface[0].network_ip} \
      -e POSTGRES_PORT=5432 \
      -e USE_DOCKER=yes \
      -e IPYTHONDIR=/app/.ipython \
      -p 8000:8000 \
      gcr.io/google-samples/hello-app:1.0
  EOF

  service_account {
    scopes = ["cloud-platform"]
  }

  tags = ["django"]
}

# Firewall rules to allow internal communication
resource "google_compute_firewall" "postgres_ingress" {
  name    = "allow-postgres-ingress"
  network = var.vpc_id

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_tags = ["django"]
  target_tags = ["postgres"]
}

resource "google_compute_firewall" "django_ingress" {
  name    = "allow-django-ingress"
  network = var.vpc_id

  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }

  source_tags = ["lb"]
  target_tags = ["django"]
}

# Load Balancer Configuration

# Health Check for Django
resource "google_compute_health_check" "django_health_check" {
  name                = "django-health-check"
  http_health_check {
    port = 8000
    request_path = "/"
  }
  check_interval_sec  = 5
  timeout_sec         = 5
  unhealthy_threshold = 3
  healthy_threshold   = 3
}

# Instance Group for Django VMs
resource "google_compute_instance_group" "django_instance_group" {
  name        = "django-instance-group"
  zone        = "${var.region}-b"
  instances   = [google_compute_instance.django.self_link]
}

# Backend Service for Django
resource "google_compute_backend_service" "django_backend" {
  name                    = "django-backend"
  protocol                = "HTTP"
  health_checks          = [google_compute_health_check.django_health_check.id]

  backend {
    group = google_compute_instance_group.django_instance_group.self_link
  }

  port_name = "http"
}

# URL Map for Load Balancer
resource "google_compute_url_map" "django_url_map" {
  name            = "django-url-map"
  default_service = google_compute_backend_service.django_backend.id
}

# HTTP Proxy for Load Balancer
resource "google_compute_target_http_proxy" "django_http_proxy" {
  name    = "django-http-proxy"
  url_map = google_compute_url_map.django_url_map.id
}

# Load Balancer Forwarding Rule
resource "google_compute_global_forwarding_rule" "django_lb_forwarding_rule" {
  name       = "django-lb-forwarding-rule"
  target     = google_compute_target_http_proxy.django_http_proxy.id
  port_range = "80"
}

# Firewall rules to allow Load Balancer traffic
resource "google_compute_firewall" "lb_ingress" {
  name    = "allow-lb-ingress"
  network = var.vpc_id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_tags = ["lb"]
  target_tags = ["django"]
}

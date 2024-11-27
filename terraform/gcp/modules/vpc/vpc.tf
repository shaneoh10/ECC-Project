# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# Public Subnets
resource "google_compute_subnetwork" "sn1" {
  name          = "${var.project_id}-public-1"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id

  private_ip_google_access = true
}

resource "google_compute_subnetwork" "sn2" {
  name          = "${var.project_id}-public-2"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id

  private_ip_google_access = true
}

# Private Subnets
resource "google_compute_subnetwork" "private_sn1" {
  name          = "${var.project_id}-private-1"
  ip_cidr_range = "10.0.3.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id

  private_ip_google_access = false
}

resource "google_compute_subnetwork" "private_sn2" {
  name          = "${var.project_id}-private-2"
  ip_cidr_range = "10.0.4.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id

  private_ip_google_access = false
}

# Cloud Router (equivalent to NAT Gateway functionality)
resource "google_compute_router" "router" {
  name    = "${var.project_id}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

# Cloud NAT
resource "google_compute_router_nat" "nat" {
  name                               = "${var.project_id}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Firewall Rules (replacing Security Groups)
# ALB Firewall Rule
resource "google_compute_firewall" "alb_fw" {
  name    = "${var.project_id}-alb-fw"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["alb"]
}

# App Firewall Rule (incoming traffic to app)
resource "google_compute_firewall" "app_fw" {
  name    = "${var.project_id}-app-fw"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }

  source_tags = ["alb"]
  target_tags = ["app"]
}

# Database Firewall Rule
resource "google_compute_firewall" "db_fw" {
  name    = "${var.project_id}-db-fw"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_tags = ["app"]
  target_tags = ["db"]
}

# Egress Firewall Rule (Allow all outbound)
resource "google_compute_firewall" "egress_fw" {
  name      = "${var.project_id}-egress-fw"
  network   = google_compute_network.vpc.id
  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
}

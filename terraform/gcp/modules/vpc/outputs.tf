output "vpc_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "public_subnet_1_id" {
  description = "The ID of the first public subnet"
  value       = google_compute_subnetwork.sn1.id
}

output "public_subnet_2_id" {
  description = "The ID of the second public subnet"
  value       = google_compute_subnetwork.sn2.id
}

output "private_subnet_1_id" {
  description = "The ID of the first private subnet"
  value       = google_compute_subnetwork.private_sn1.id
}

output "private_subnet_2_id" {
  description = "The ID of the second private subnet"
  value       = google_compute_subnetwork.private_sn2.id
}

output "alb_firewall_rule_id" {
  description = "The ID of the ALB firewall rule"
  value       = google_compute_firewall.alb_fw.id
}

output "cloud_router_id" {
  description = "The ID of the Cloud Router"
  value       = google_compute_router.router.id
}

output "cloud_nat_id" {
  description = "The ID of the Cloud NAT"
  value       = google_compute_router_nat.nat.id
}

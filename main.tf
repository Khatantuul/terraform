# main.tf

provider "google" {
  project     = var.project_id
  region      = var.region
}

resource "google_compute_network" "vpc" {
  for_each = var.all_vpcs

  name                    = each.value.name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "webapp-subnet" {
  for_each = var.all_vpcs

  name          = each.value.webappsubnet
  network       = google_compute_network.vpc[each.key].self_link
  ip_cidr_range = each.value.webappsubnetcidr
}

resource "google_compute_subnetwork" "db-subnet" {
  for_each = var.all_vpcs 

  name          = each.value.dbsubnet
  network       = google_compute_network.vpc[each.key].self_link
  ip_cidr_range = each.value.dbsubnetcidr
}

resource "google_compute_route" "webapp_route" {
  for_each = var.all_vpcs

  name                = "webapp-route"
  network             = google_compute_network.vpc[each.key].self_link
  dest_range  = "0.0.0.0/0"
  next_hop_gateway    = "default-internet-gateway" 
  tags = ["route-webapp"]
}

resource "google_compute_firewall" "allow_traffic" {
  for_each = var.all_vpcs

  name    = "testt"
  network = google_compute_network.vpc[each.key].self_link
  priority = 1000
  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports = ["8080","80"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["route-webapp"]
  depends_on = [google_compute_network.vpc]
  
}

resource "google_compute_firewall" "deny_ssh_login" {
  for_each = var.all_vpcs

  name    = "denial"
  network = google_compute_network.vpc[each.key].self_link
  
   deny {
    protocol = "tcp"
    ports    = ["20"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["route-webapp"]
  depends_on = [google_compute_network.vpc]
  
}

resource "google_compute_instance" "my-instance" {
  for_each = var.all_vpcs

  name         = "my-instance-${each.key}"
  machine_type = "e2-medium"  
  zone         = "us-east1-b"

  boot_disk {
    initialize_params {
      image = each.value.image
      size = each.value.size
      type = each.value.disktype
    }
    mode = "READ_WRITE"
  }

  
  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }
   subnetwork = google_compute_subnetwork.webapp-subnet[each.key].id

  }

  tags = ["route-webapp"]  
}
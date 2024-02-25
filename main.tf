# main.tf

provider "google" {
  project     = var.project_id
  region      = var.region
}

resource "google_compute_network" "vpc" {
  for_each = var.all_vpcs

  name                    = each.value.name
  auto_create_subnetworks = each.value.autocreatesubnetworks
  routing_mode            = each.value.routingmode
  delete_default_routes_on_create = each.value.deletedefaultroutesoncreate
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

  name                = each.value.webapproute
  network             = google_compute_network.vpc[each.key].self_link
  dest_range  = each.value.webapproute_dest_range
  next_hop_gateway    = each.value.webapp_next_hop_gateway
  tags = ["route-webapp"]
}

resource "google_compute_firewall" "allow_traffic" {
  for_each = var.all_vpcs

  name    = each.value.firewall_allow_name
  network = google_compute_network.vpc[each.key].self_link
  priority = 1000
  direction = each.value.firewall_allow_direction
  allow {
    protocol = "tcp"
    ports = each.value.firewall_allow_ports
  }
  source_ranges = each.value.firewall_source_ranges
  target_tags = ["route-webapp"]
  depends_on = [google_compute_network.vpc]
  
}

resource "google_compute_firewall" "deny_ssh_login" {
  for_each = var.all_vpcs

  name    = each.value.firewall_deny_name
  network = google_compute_network.vpc[each.key].self_link
  
   deny {
    protocol = "tcp"
    ports    = each.value.firewall_deny_ports
  }
  source_ranges = each.value.firewall_source_ranges
  target_tags = ["route-webapp"]
  depends_on = [google_compute_network.vpc]
  
}

resource "google_compute_instance" "my-instance" {
  for_each = var.all_vpcs

  name         = "my-instance-${each.key}"
  machine_type = each.value.vm_machine_type 
  zone         = each.value.vm_zone

  boot_disk {
    initialize_params {
      image = each.value.image
      size = each.value.size
      type = each.value.disktype
    }
    mode = each.value.vm_disk_mode
  }

  
  network_interface {
    access_config {
      network_tier = each.value.vm_networking_tier
    }
   subnetwork = google_compute_subnetwork.webapp-subnet[each.key].id

  }

  tags = ["route-webapp"]  
}
# main.tf

provider "google" {
  credentials = file("/Users/khatna/Downloads/compact-haiku-414222-e35cdefbc10a.json")
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
}

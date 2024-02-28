# main.tf

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc" {
  for_each = var.all_vpcs

  name                            = each.value.name
  auto_create_subnetworks         = each.value.autocreatesubnetworks
  routing_mode                    = each.value.routingmode
  delete_default_routes_on_create = each.value.deletedefaultroutesoncreate
}

resource "google_compute_subnetwork" "webapp-subnet" {
  for_each = var.all_vpcs

  name                     = each.value.webappsubnet
  network                  = google_compute_network.vpc[each.key].self_link
  ip_cidr_range            = each.value.webappsubnetcidr
  private_ip_google_access = each.value.private_ip_google_access
  depends_on               = [google_compute_network.vpc]
}

resource "google_compute_subnetwork" "db-subnet" {
  for_each = var.all_vpcs

  name          = each.value.dbsubnet
  network       = google_compute_network.vpc[each.key].self_link
  ip_cidr_range = each.value.dbsubnetcidr
}

resource "google_compute_route" "webapp_route" {
  for_each = var.all_vpcs

  name             = each.value.webapproute
  network          = google_compute_network.vpc[each.key].self_link
  dest_range       = each.value.webapproute_dest_range
  next_hop_gateway = each.value.webapp_next_hop_gateway
  tags             = each.value.webapp_route_tags
  depends_on       = [google_compute_network.vpc]
}

resource "google_compute_firewall" "allow_traffic" {
  for_each = var.all_vpcs

  name      = each.value.firewall_allow_name
  network   = google_compute_network.vpc[each.key].self_link
  priority  = each.value.firewall_allow_priority
  direction = each.value.firewall_allow_direction
  allow {
    protocol = each.value.firewall_allow_protocol
    ports    = each.value.firewall_allow_ports
  }
  source_ranges = each.value.firewall_source_ranges
  target_tags   = each.value.firewall_allow_target_tags
  depends_on    = [google_compute_network.vpc]

}

resource "google_compute_firewall" "deny_ssh_login" {
  for_each = var.all_vpcs

  name    = each.value.firewall_deny_name
  network = google_compute_network.vpc[each.key].self_link

  deny {
    protocol = each.value.firewall_allow_protocol
    ports    = each.value.firewall_deny_ports
  }
  source_ranges = each.value.firewall_source_ranges
  target_tags   = each.value.firewall_allow_target_tags
  depends_on    = [google_compute_network.vpc]

}

resource "google_compute_instance" "my-instance" {
  for_each = var.all_vpcs

  name         = "${each.value.vm_name}-${each.key}"
  machine_type = each.value.vm_machine_type
  zone         = each.value.vm_zone

  boot_disk {
    initialize_params {
      image = each.value.image
      size  = each.value.size
      type  = each.value.disktype
    }
    mode = each.value.vm_disk_mode
  }

  network_interface {
    access_config {
      network_tier = each.value.vm_networking_tier
    }
    subnetwork = google_compute_subnetwork.webapp-subnet[each.key].id

  }

  tags = each.value.webapp_route_tags
  //make db IP dynamic
  metadata_startup_script = <<-EOT
    #!/bin/bash

    echo "spring.datasource.url=jdbc:postgresql://${each.value.cloudsql_private_ip_address}:${each.value.cloudsql_port}/webapp" > /opt/application.properties
    echo "spring.datasource.username=${google_sql_user.postgres-db-user[each.key].name}" >> /opt/application.properties
    echo "spring.datasource.password=${google_sql_user.postgres-db-user[each.key].password}" >> /opt/application.properties
    echo "spring.datasource.hikari.connection-timeout=3000" >> /opt/application.properties
    echo "spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect" >> /opt/application.properties
    echo "spring.jpa.hibernate.ddl-auto=update" >> /opt/application.properties
    echo "spring.jpa.show-sql=true" >> /opt/application.properties
    echo "spring.jpa.properties.hibernate.format_sql=true"
  
  EOT

  depends_on = [google_sql_database_instance.postgres-db-instance]
}

resource "google_compute_global_address" "private_ip_address" {
  for_each = var.all_vpcs

  provider      = google-beta
  project       = var.project_id
  name          = each.value.private_ip_name
  purpose       = each.value.private_ip_purpose
  address_type  = each.value.private_ip_address_type
  prefix_length = each.value.private_ip_prefix_length
  network       = google_compute_network.vpc[each.key].self_link
}



resource "google_service_networking_connection" "private_vpc_connection" {
  for_each = var.all_vpcs
  provider = google-beta

  network = google_compute_network.vpc[each.key].self_link
  service = each.value.private_vpc_connection_service

  reserved_peering_ranges = [google_compute_global_address.private_ip_address[each.key].name]
}

resource "random_id" "db_name_suffix" {
  byte_length = var.db_name_suffix_length
}

resource "google_sql_database_instance" "postgres-db-instance" {
  for_each = var.all_vpcs

  provider            = google-beta
  project             = var.project_id
  region              = var.region
  name                = "${each.value.postgres_db_instance_name}-${random_id.db_name_suffix.hex}"
  database_version    = each.value.postgres_db_version
  deletion_protection = each.value.postgres_deletion_protection

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {

    tier              = each.value.db_tier
    edition           = each.value.db_edition
    availability_type = each.value.db_availability_type
    disk_type         = each.value.db_disk_type
    disk_size         = each.value.db_disk_size
    ip_configuration {
      ipv4_enabled    = each.value.db_instance_ipv4_enabled
      private_network = google_compute_network.vpc[each.key].self_link

    }

  }
}

resource "google_sql_database" "postgres-db" {
  for_each = var.all_vpcs
  name     = each.value.postgres_db_name
  instance = google_sql_database_instance.postgres-db-instance[each.key].name
}

resource "random_password" "password" {
  length  = 8
  special = true
  number  = true
  upper   = true
  lower   = true
}

resource "google_sql_user" "postgres-db-user" {
  for_each = var.all_vpcs
  name     = each.value.postgres_db_user_name
  instance = google_sql_database_instance.postgres-db-instance[each.key].name
  password = random_password.password.result
}
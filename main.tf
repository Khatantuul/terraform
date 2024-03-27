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

    echo "spring.datasource.url=jdbc:postgresql://${google_sql_database_instance.postgres-db-instance[each.key].ip_address.0.ip_address}:${each.value.cloudsql_port}/webapp" > /opt/application.properties
    echo "spring.datasource.username=${google_sql_user.postgres-db-user[each.key].name}" >> /opt/application.properties
    echo "spring.datasource.password=${google_sql_user.postgres-db-user[each.key].password}" >> /opt/application.properties
    echo "spring.datasource.hikari.connection-timeout=3000" >> /opt/application.properties
    echo "spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect" >> /opt/application.properties
    echo "spring.jpa.hibernate.ddl-auto=update" >> /opt/application.properties
    echo "spring.jpa.show-sql=true" >> /opt/application.properties
    echo "spring.jpa.properties.hibernate.format_sql=true"
    echo "PROJECT_NAME=${var.project_id}" >> /opt/application.properties
    echo "TOPIC_NAME=${google_pubsub_topic.topic[each.key].name}" >> /opt/application.properties
  
  EOT


  service_account {
    email  = google_service_account.service_account[each.key].email
    scopes = ["cloud-platform"]
  }

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



resource "google_service_account" "service_account" {
  for_each = var.all_vpcs
  account_id   = each.value.service_account_id
  # display_name = "Khatnaa Service Account"
}



resource "google_project_iam_binding" "iam_bind" {
  for_each = var.all_vpcs
  project = var.project_id
  role    = each.value.iam_bind_logging_role

  members = [
    "serviceAccount:${google_service_account.service_account[each.key].email}",
  ]
}
resource "google_project_iam_binding" "iam_bind_two" {
  for_each = var.all_vpcs
  project = var.project_id
  role    = each.value.iam_bind_monitoring_role

  members = [
    "serviceAccount:${google_service_account.service_account[each.key].email}",
  ]
}

resource "google_project_iam_binding" "iam_bind_pubsub_editor" {
  for_each = var.all_vpcs
  project  = var.project_id
  role     = each.value.iam_bind_pubsub_editor_role

  members = [
    "serviceAccount:${google_service_account.service_account[each.key].email}",
  ]
}



resource "google_pubsub_topic" "topic" {
  for_each = var.all_vpcs
  name = each.value.pubsub_topic_name 
  project = var.project_id
  message_retention_duration = each.value.topic_message_duration
  # depends_on = [ google_service_account.service_account ]

}

resource "google_pubsub_subscription" "example" {
  for_each = var.all_vpcs
  name  = each.value.pubsub_subscription_name
  topic = google_pubsub_topic.topic[each.key].id

  ack_deadline_seconds = each.value.subscription_ack_deadline_seconds

}


resource "google_dns_record_set" "example_record" {
  for_each = var.all_vpcs
  name    = each.value.domain
  type    = each.value.dns_record_type_A
  ttl     = each.value.cache_ttl
  managed_zone = each.value.dns_managed_zone
  rrdatas = [google_compute_instance.my-instance[each.key].network_interface[0].access_config[0].nat_ip]
}

resource "google_vpc_access_connector" "connector" {
  for_each = var.all_vpcs
  name          = each.value.vpc_access_connector_name
  ip_cidr_range = each.value.vpc_access_connector_ip_range
  network       = google_compute_network.vpc[each.key].self_link
}

resource "google_service_account" "service_account_cloudfunc" {
  for_each = var.all_vpcs
  account_id   = each.value.service_account_cloudfunc_id
}

resource "google_project_iam_binding" "iam_bind_cloudfunc" {
  for_each = var.all_vpcs
  project  = var.project_id
  role     = each.value.iam_bind_pubsub_subscriber_role

  members = [
    "serviceAccount:${google_service_account.service_account_cloudfunc[each.key].email}",
  ]
}
resource "google_cloudfunctions2_function" "function" {
  for_each = var.all_vpcs
  name = each.value.cloud_function_name
  location = var.region
    build_config {
    runtime = each.value.cloud_function_build_lang
    entry_point = each.value.cloud_function_entry_point 
    source {
      storage_source {
        bucket = each.value.cloud_bucket_name
        object = each.value.cloud_function_source
      }
    }

    
  }

    service_config {
    max_instance_count  = each.value.cloud_func_max_instances
    min_instance_count = each.value.cloud_func_min_instances
    available_memory    = each.value.cloud_func_available_memory
    timeout_seconds     = each.value.cloud_func_timeout
    max_instance_request_concurrency = each.value.max_instance_request_concurrency
    available_cpu = each.value.cloud_func_available_cpu
    environment_variables = {
        DB_URL = "jdbc:postgresql://${google_sql_database_instance.postgres-db-instance[each.key].ip_address.0.ip_address}:${each.value.cloudsql_port}/webapp"
        DB_USER = "${google_sql_user.postgres-db-user[each.key].name}"
        DB_PASSWORD = "${google_sql_user.postgres-db-user[each.key].password}"
    }
    ingress_settings = each.value.cloud_func_ingress_settings
    all_traffic_on_latest_revision = each.value.all_traffic_on_latest_revision
    service_account_email = google_service_account.service_account_cloudfunc[each.key].email
    vpc_connector_egress_settings = each.value.vpc_connector_egress_settings
    vpc_connector = google_vpc_access_connector.connector[each.key].id
  }

  event_trigger {
    trigger_region = var.region
    event_type = each.value.cloud_func_event_type
    pubsub_topic = google_pubsub_topic.topic[each.key].id
    retry_policy = each.value.cloud_func_retry_policy
  }

  

}



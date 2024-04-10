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

resource "google_compute_subnetwork" "load-balancer-subnet" {
  for_each = var.all_vpcs
  region = var.region
  purpose = each.value.lb_subnet_purpose
  name          = each.value.dbsubnet
  network       = google_compute_network.vpc[each.key].self_link
  ip_cidr_range = each.value.dbsubnetcidr
  role = each.value.lb_subnet_role
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



# resource "google_compute_instance" "my-instance" {
#   for_each = var.all_vpcs

#   name         = "${each.value.vm_name}-${each.key}"
#   machine_type = each.value.vm_machine_type
#   zone         = each.value.vm_zone

#   boot_disk {
#     initialize_params {
#       image = each.value.image
#       size  = each.value.size
#       type  = each.value.disktype
#     }
#     mode = each.value.vm_disk_mode
#   }

#   network_interface {
#     access_config {
#       network_tier = each.value.vm_networking_tier
#     }
#     subnetwork = google_compute_subnetwork.webapp-subnet[each.key].id

#   }

#   tags = each.value.webapp_route_tags
#   //make db IP dynamic
#   metadata_startup_script = <<-EOT
#     #!/bin/bash

#     echo "spring.datasource.url=jdbc:postgresql://${google_sql_database_instance.postgres-db-instance[each.key].ip_address.0.ip_address}:${each.value.cloudsql_port}/webapp" > /opt/application.properties
#     echo "spring.datasource.username=${google_sql_user.postgres-db-user[each.key].name}" >> /opt/application.properties
#     echo "spring.datasource.password=${google_sql_user.postgres-db-user[each.key].password}" >> /opt/application.properties
#     echo "spring.datasource.hikari.connection-timeout=3000" >> /opt/application.properties
#     echo "spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect" >> /opt/application.properties
#     echo "spring.jpa.hibernate.ddl-auto=update" >> /opt/application.properties
#     echo "spring.jpa.show-sql=true" >> /opt/application.properties
#     echo "spring.jpa.properties.hibernate.format_sql=true"
#     echo "PROJECT_NAME=${var.project_id}" >> /opt/application.properties
#     echo "TOPIC_NAME=${google_pubsub_topic.topic[each.key].name}" >> /opt/application.properties
  
#   EOT


#   service_account {
#     email  = google_service_account.service_account[each.key].email
#     scopes = ["cloud-platform"]
#   }

#   depends_on = [google_sql_database_instance.postgres-db-instance]
# }

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



# resource "google_kms_crypto_key_iam_binding" "im_binding_key_for_sql" {
#   for_each = var.all_vpcs
#   provider      = google-beta
#   crypto_key_id = google_kms_crypto_key.sql_key.id
#   role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

#   members = [
#     "serviceAccount:${google_service_account.service_account_for_cloud_sql[each.key].email}",
#   ]
# }


# resource "google_project_iam_binding" "cloudsql_admin_binding" {
#   for_each = var.all_vpcs

#   project = var.project_id
#   role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

#   members = [
#     "serviceAccount:${google_service_account.service_account_for_cloud_sql[each.key].email}",
#   ]

#   # Define this binding to depend on the service account creation
#   depends_on = [google_kms_crypto_key.sql_key]
# }

resource "google_project_service_identity" "gcp_sa_cloud_sql" {
  for_each = var.all_vpcs
  provider = google-beta
  project = var.project_id
  service  = each.value.google_project_service_identity_service
} 

resource "google_kms_crypto_key_iam_binding" "crypto_key" {
  for_each = var.all_vpcs
  provider      = google-beta
  crypto_key_id = google_kms_crypto_key.sql_key[each.key].id
  role          = each.value.crypto_key_role

  members = [
    "serviceAccount:${google_project_service_identity.gcp_sa_cloud_sql[each.key].email}",
  ]
}

resource "google_sql_database_instance" "postgres-db-instance" {
  for_each = var.all_vpcs

  provider            = google-beta
  project             = var.project_id
  region              = var.region
  name                = "${each.value.postgres_db_instance_name}-${random_id.db_name_suffix.hex}"
  database_version    = each.value.postgres_db_version
  deletion_protection = each.value.postgres_deletion_protection
  encryption_key_name = google_kms_crypto_key.sql_key[each.key].id
  
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
     database_flags {
      name  = "max_connections"
      value = "100"  
    }
    
  }
  
  
}

resource "google_project_iam_member" "project_kms_admin" {
  for_each = var.all_vpcs
  project = var.project_id
  role    = each.value.cloud_kms_admin_role
  member  = "serviceAccount:${google_service_account.service_account[each.key].email}"
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

resource "google_project_iam_binding" "im_binding_key_for_instemplate_two" {
  for_each = var.all_vpcs

  project      = var.project_id
  role          = each.value.crypto_key_role

  members = [
    "serviceAccount:${google_service_account.service_account[each.key].email}",
  ]
}

data "google_storage_project_service_account" "gcs_account" {
}

resource "google_kms_crypto_key_iam_binding" "binding" {
  for_each = var.all_vpcs
  crypto_key_id = google_kms_crypto_key.storage_key[each.key].id
  role          = each.value.crypto_key_role

  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}

resource "google_storage_bucket" "example_bucket" {
  for_each = var.all_vpcs
  name     = each.value.cloud_bucket_name
  location = var.region
  storage_class = each.value.cloud_bucket_storage_class
  encryption {
    default_kms_key_name = google_kms_crypto_key.storage_key[each.key].id
  }
  force_destroy = each.value.cloud_bucket_force_destroy
  depends_on = [google_kms_crypto_key_iam_binding.binding]
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
  rrdatas = [google_compute_forwarding_rule.default[each.key].ip_address]
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

resource "google_compute_region_instance_template" "instance_template" {
  for_each = var.all_vpcs
  name = "${each.value.vm_name}-template"
  region = var.region
  project = var.project_id
  machine_type = each.value.vm_machine_type
  tags         = each.value.instance_template_tags

  service_account {
    email  = google_service_account.service_account[each.key].email
    scopes = ["cloud-platform"]
  }
  disk{
    source_image = each.value.image
    auto_delete = each.value.instance_template_disk_auto_delete
    boot = each.value.instance_template_disk_boot
    source_image_encryption_key {
      kms_key_service_account = google_service_account.service_account[each.key].email
      kms_key_self_link = google_kms_crypto_key.vm_key[each.key].id
    }
    disk_encryption_key {
      kms_key_self_link = google_kms_crypto_key.vm_key[each.key].id
    }
  }

  

 
   network_interface {
    access_config {
      network_tier = each.value.vm_networking_tier
    }
    subnetwork = google_compute_subnetwork.webapp-subnet[each.key].id

  }

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

  #  service_account {
  #   email  = google_service_account.service_account[each.key].email
  #   scopes = ["cloud-platform"]
  # }
   lifecycle {
    create_before_destroy = true
  }


}

resource "google_compute_region_health_check" "http-health-check" {
  for_each = var.all_vpcs
  name        = var.health_check_name
  # description = "Health check via http"
  region = var.region

  timeout_sec         = each.value.health_check_timeout_sec
  check_interval_sec  = each.value.health_check_check_interval
  healthy_threshold   = each.value.health_check_healthy_threshold
  unhealthy_threshold = each.value.health_check_unhealthy_threshold

  http_health_check {
    port               = each.value.health_check_port
    request_path       = each.value.health_check_request_path
  }
  log_config {
    enable = each.value.health_check_log_enable
  }
}



resource "google_compute_region_instance_group_manager" "mig" {
  for_each = var.all_vpcs
  name = each.value.mig_name

  base_instance_name         = each.value.mig_base_instance_name
  project = var.project_id
  region                     = var.region
  distribution_policy_zones  = each.value.mig_distribution_policy_zones

  
  version {
    instance_template = google_compute_region_instance_template.instance_template[each.key].self_link
  }

 
  named_port {
    name = each.value.mig_named_port
    port = each.value.health_check_port
  }

  auto_healing_policies {
    health_check      = google_compute_region_health_check.http-health-check[each.key].id
    initial_delay_sec = each.value.mig_autohealing_policy_initial_delay_sec
  }
}

resource "google_compute_region_autoscaler" "autoscaler" {
  for_each = var.all_vpcs
  name   = each.value.autoscaler_name
  region = var.region
  target = google_compute_region_instance_group_manager.mig[each.key].id

  autoscaling_policy {
    max_replicas    = each.value.autoscaler_max_replicas
    min_replicas    = each.value.autoscaler_min_replicas
    cooldown_period = each.value.autoscaler_cooldown_period
    mode = each.value.autoscaler_mode

    cpu_utilization {
      target = each.value.autoscaler_cpu_utilization
    }
  }
}


resource "google_compute_region_ssl_certificate" "default" {
  for_each = var.all_vpcs
  region      = var.region
  name_prefix = each.value.ssl_cert_name_prefix
  private_key = file(var.ss_cert_private_key)
  certificate = file(var.ss_cert_certificate_path)

  lifecycle {
    create_before_destroy = true
  }
}
resource "google_compute_region_ssl_policy" "prod-ssl-policy" {
  for_each = var.all_vpcs
  name    = each.value.ssl_policy_name
  region = var.region
  profile = each.value.ssl_policy_profile
}

# 

resource "google_compute_region_target_https_proxy" "default" {
  for_each = var.all_vpcs
 project = var.project_id
 region = var.region
 name             = each.value.target_https_proxy_name
 url_map          = google_compute_region_url_map.default[each.key].id

  provider = google-beta
  ssl_certificates = [
    google_compute_region_ssl_certificate.default[each.key].id
  ]
  depends_on = [
    google_compute_region_ssl_certificate.default
  ]
# }
}

resource "google_compute_address" "default" {
  for_each = var.all_vpcs
  provider = google-beta
  name     = each.value.compute_address_name
  project  = var.project_id
  region   = var.region
}


resource "google_compute_forwarding_rule" "default" {
  for_each = var.all_vpcs
  name                  = each.value.compute_forwarding_rule_name
  provider              = google
  network = google_compute_network.vpc[each.key].id
  network_tier = each.value.vm_networking_tier
  ip_protocol           = each.value.compute_forwarding_rule_ip_protocol
  load_balancing_scheme = each.value.compute_forwarding_rule_lb_scheme
  port_range            = each.value.compute_forwarding_rule_port
  target                = google_compute_region_target_https_proxy.default[each.key].id //so the load balancer above will receive the traffic
  ip_address            = google_compute_address.default[each.key].id 
  depends_on = [ google_compute_subnetwork.load-balancer-subnet ]
}

resource "google_compute_region_url_map" "default" {
  for_each = var.all_vpcs
  name            = each.value.compute_region_url_map_name
  provider        = google-beta
  project       = var.project_id
  region = var.region
  default_service = google_compute_region_backend_service.default[each.key].id
}


resource "google_compute_region_backend_service" "default" {
  for_each = var.all_vpcs
  load_balancing_scheme = each.value.compute_forwarding_rule_lb_scheme

  backend {
    group          = google_compute_region_instance_group_manager.mig[each.key].instance_group
    balancing_mode = each.value.backend_service_balancing_mode
    capacity_scaler = each.value.backend_service_capacity_scaler
  }

  region      = var.region
  name        = each.value.backend_service_name
  protocol    = each.value.backend_service_protocol
  timeout_sec = each.value.backend_service_timeout

  health_checks = [google_compute_region_health_check.http-health-check[each.key].id]
}




resource "google_compute_firewall" "allow_health_check" {
  for_each = var.all_vpcs
  name = each.value.compute_firewall_allow_health_check_name
  allow {
    protocol = each.value.compute_firewall_allow_health_check_allow_protocol
  }
  direction     = each.value.compute_firewall_allow_health_check_direction
  network       = google_compute_network.vpc[each.key].id
  priority      = each.value.compute_firewall_allow_health_check_priority
  source_ranges = each.value.compute_firewall_allow_health_check_source_ranges
  target_tags   = google_compute_region_instance_template.instance_template[each.key].tags
}

resource "google_compute_firewall" "allow_proxy" {
  for_each = var.all_vpcs
  name = each.value.compute_firewall_allow_proxy_name
  allow {
    ports    = each.value.compute_firewall_allow_proxy_allow_ports
    protocol = each.value.compute_firewall_allow_health_check_allow_protocol
  }

  direction     = each.value.compute_firewall_allow_health_check_direction
  network       = google_compute_network.vpc[each.key].id
  priority      = each.value.compute_firewall_allow_health_check_priority
  source_ranges = [google_compute_subnetwork.load-balancer-subnet[each.key].ip_cidr_range]
  target_tags   = google_compute_region_instance_template.instance_template[each.key].tags
}

resource "google_kms_key_ring" "my_key_ring2" {
  for_each = var.all_vpcs
  name     = each.value.cloud_key_ring_name
  location = var.region
}

resource "google_kms_crypto_key" "vm_key" {
  for_each = var.all_vpcs
  name       = each.value.crypto_vm_key_name
  key_ring   = google_kms_key_ring.my_key_ring2[each.key].id
  purpose    = each.value.crypto_key_purpose
  rotation_period = each.value.crypto_key_rotation_period
    lifecycle {
    prevent_destroy = false
  }
}

resource "google_kms_crypto_key_iam_binding" "vm_key_binding" {
  for_each = var.all_vpcs
  provider      = google-beta
  crypto_key_id = google_kms_crypto_key.vm_key[each.key].id
  role          = each.value.crypto_key_role

  members = [
    "serviceAccount:${each.value.crypto_vm_binding_sa}",
  ]
}

resource "google_kms_crypto_key" "sql_key" {
  for_each = var.all_vpcs
  name       = each.value.crypto_sql_key_name
  key_ring   = google_kms_key_ring.my_key_ring2[each.key].id
  purpose    = each.value.crypto_key_purpose
  rotation_period = each.value.crypto_key_rotation_period
    lifecycle {
    prevent_destroy = false
  }
}



resource "google_kms_crypto_key" "storage_key" {
  for_each = var.all_vpcs
  name       = each.value.crypto_storage_key_name
  key_ring   = google_kms_key_ring.my_key_ring2[each.key].id
  purpose    = each.value.crypto_key_purpose
  rotation_period = each.value.crypto_key_rotation_period
    lifecycle {
    prevent_destroy = false
  }
}
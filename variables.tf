# variables.tf

variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "db_name_suffix_length"{
  type = number
}
variable "health_check_name"{
  type = string
}

variable "ss_cert_private_key" {
  type    = string
  default = "/Users/khatna/lb_ssl.key"
}

variable "ss_cert_certificate_path" {
  type    = string
  default = "/Users/khatna/lb_ssl/khatan_me.crt"
}


variable "all_vpcs" {
  type = map(object({
    name                        = string
    autocreatesubnetworks       = bool
    routingmode                 = string
    deletedefaultroutesoncreate = bool
    webappsubnet                = string
    webappsubnetcidr            = string
    private_ip_google_access    = bool
    webapproute                 = string
    webapproute_dest_range      = string
    webapp_next_hop_gateway     = string
    webapp_route_tags           = list(string)
    dbsubnet                    = string
    dbsubnetcidr                = string
    firewall_allow_name         = string
    firewall_allow_direction    = string
    firewall_allow_priority     = number
    firewall_allow_protocol     = string
    firewall_allow_ports        = list(string)
    firewall_allow_target_tags  = list(string)
    firewall_source_ranges      = list(string)
    firewall_deny_name          = string
    firewall_deny_ports         = list(string)
    image                       = string
    size                        = string
    disktype                    = string
    vm_name                     = string
    vm_zone                     = string
    vm_machine_type             = string
    vm_networking_tier          = string
    vm_disk_mode                = string
    private_ip_name             = string
    private_ip_purpose          = string
    private_ip_address_type     = string
    private_ip_prefix_length    = number
    # cloudsql_private_ip_address = string
    cloudsql_port               = string
    private_vpc_connection_service = string
    postgres_db_instance_name   = string
    postgres_db_version         = string
    postgres_deletion_protection = bool
    db_tier                     = string
    db_edition                 = string
    db_availability_type        = string
    db_disk_type                = string
    db_disk_size               = number
    db_instance_ipv4_enabled  = bool
    postgres_db_name          = string
    postgres_db_user_name = string
    service_account_id = string
    service_account_cloudfunc_id = string
    service_account_cloudsql_id = string
    iam_bind_logging_role = string
    iam_bind_monitoring_role = string
    iam_bind_pubsub_editor_role = string
    iam_bind_pubsub_subscriber_role = string
    domain = string
    dns_record_type_A = string
    cache_ttl = number
    dns_managed_zone = string
    pubsub_topic_name = string
    topic_message_duration = string
    pubsub_subscription_name = string
    subscription_ack_deadline_seconds = number
    vpc_access_connector_name = string
    vpc_access_connector_ip_range = string
    cloud_function_name = string
    cloud_function_build_lang = string
    cloud_function_entry_point = string
    cloud_bucket_name = string
    cloud_bucket_storage_class = string
    cloud_bucket_force_destroy = bool
    cloud_function_source = string
    cloud_func_min_instances = number
    cloud_func_max_instances = number
    cloud_func_available_memory = string
    cloud_func_timeout = number
    max_instance_request_concurrency = number
    cloud_func_available_cpu = string
    cloud_func_ingress_settings = string
    all_traffic_on_latest_revision = bool
    vpc_connector_egress_settings = string
    cloud_func_event_type = string
    cloud_func_retry_policy = string
    lb_subnet_purpose = string
    lb_subnet_role = string
    instance_template_tags = list(string)
    instance_template_disk_auto_delete = bool
    instance_template_disk_boot = bool
    # instance_template_lifecycle_create_before_destroy = bool
    health_check_timeout_sec = number
    health_check_check_interval = number
    health_check_healthy_threshold = number
    health_check_unhealthy_threshold = number
    health_check_port = number
    health_check_request_path = string
    health_check_log_enable = bool
    mig_name = string
    mig_base_instance_name = string
    mig_distribution_policy_zones = list(string)
    mig_named_port = string
    mig_autohealing_policy_initial_delay_sec = number
    autoscaler_name = string
    autoscaler_max_replicas = number
    autoscaler_min_replicas = number
    autoscaler_cooldown_period = number
    autoscaler_mode = string
    autoscaler_cpu_utilization = number
    ssl_cert_name_prefix = string
    # ss_cert_private_key = file(path)
    # ss_cert_certificate_path = file(path)
    ssl_policy_name = string
    ssl_policy_profile = string
    target_https_proxy_name = string
    compute_address_name = string
    compute_forwarding_rule_name = string
    compute_forwarding_rule_ip_protocol = string
    compute_forwarding_rule_lb_scheme = string
    compute_forwarding_rule_port= string
    compute_region_url_map_name  = string
    backend_service_balancing_mode = string
    backend_service_capacity_scaler = number
    backend_service_name = string
    backend_service_protocol = string
    backend_service_timeout = number
    compute_firewall_allow_health_check_name = string
    compute_firewall_allow_health_check_allow_protocol = string
    compute_firewall_allow_health_check_direction = string
    compute_firewall_allow_health_check_priority = number
    compute_firewall_allow_health_check_source_ranges = list(string)
    compute_firewall_allow_proxy_name = string
    compute_firewall_allow_proxy_allow_ports = list(string)
    crypto_key_role = string
    google_project_service_identity_service = string
    cloud_kms_admin_role = string
    cloud_key_ring_name = string
    crypto_vm_key_name = string
    crypto_sql_key_name = string
    crypto_storage_key_name = string
    crypto_key_purpose = string
    crypto_key_rotation_period = string
    crypto_vm_binding_sa = string
  }))
}
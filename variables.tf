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
  }))
}
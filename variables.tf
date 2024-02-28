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
    cloudsql_private_ip_address = string
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
          
  }))
}
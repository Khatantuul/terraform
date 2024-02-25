# variables.tf

variable "project_id" {
  description = "Google Cloud project ID"
  type = string
}

variable "region" {
  description = "GCP region"
  type = string 
}

variable "all_vpcs" {
  type = map(object({
    name            = string
    autocreatesubnetworks = bool
    routingmode = string
    deletedefaultroutesoncreate = bool 
    webappsubnet       = string
    webappsubnetcidr  = string
    webapproute = string
    webapproute_dest_range = string
    webapp_next_hop_gateway = string
    dbsubnet           = string
    dbsubnetcidr      = string
    firewall_allow_name = string
    firewall_allow_direction = string
    firewall_allow_ports = list(string)
    firewall_source_ranges = list(string)
    firewall_deny_name = string
    firewall_deny_ports = list(string)
    image = string
    size = string
    disktype = string
    vm_zone = string
    vm_machine_type = string
    vm_networking_tier = string
    vm_disk_mode = string
  }))
}
# variables.tf

variable "project_id" {
  description = "Google Cloud project ID"
}

variable "region" {
  description = "GCP region"
}

variable "all_vpcs" {
  type = map(object({
    name            = string
    webappsubnet       = string
    webappsubnetcidr  = string
    dbsubnet           = string
    dbsubnetcidr      = string
    
  }))
}
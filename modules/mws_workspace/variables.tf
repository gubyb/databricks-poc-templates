variable "databricks_account_id" {
  type = string
}

variable "credentials_id" {
  type = string
}

variable "prefix" {
  type = string // should be a randomized string  
}

variable "region" {
  type = string
}

variable "workspace_name" {
  type = string
}

// for network config
variable "existing_vpc_id" {
  type = string
}

variable "nat_gateways_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "private_subnet_pair" {
  type = list(string)
}

#One per subnet
variable "availability_zones" {
  type = list(string)
}

variable "root_bucket_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "workspace_admins" {
  type = list(string)
  default = []
}

variable "databricks_client_id" {
  type      = string
  sensitive = true
}

variable "metastore_id" {
  type = string
  default = null
}

variable "managed_storage_cmk" {
  type = string
  default = null
}

variable "workspace_storage_cmk" {
  type = string
  default = null
}

variable "private_dns_enabled" {
  type = bool
  description = "Can only be true for one workspace, DNS applied across the VPC"
}

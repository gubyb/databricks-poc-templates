variable "databricks_client_id" {
  type      = string
  sensitive = true
}

variable "databricks_client_secret" {
  type      = string
  sensitive = true
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks Account ID"
}

variable "azure_sub_id" {
  type        = string
  description = "Azure sub ID"
}

variable "azure_tenant_id" {
  type        = string
  description = "Azure tenant ID"
}

variable "region" {
  type        = string
  description = "Azure region to deploy to"
  default     = "West Europe"
}

variable "prefix" {
  type        = string
  description = "Prefix to use"
  default     = "tf-modular-deploy"
}

variable "tags" {
  default     = {}
  type        = map(string)
  description = "Optional tags to add to created resources"
}

variable "vpc_cidr" {
  default = "10.109.0.0/17"
}

variable "admins" {
  type    = list(string)
}

variable "workspaces" {
  type = list(object({
    private_subnet_pair = object({
      subnet1_cidr = string,
      subnet2_cidr = string
    })
    workspace_name = string
    prefix = string
    root_bucket_name = string
    tags = map(string)
    workspace_admins = list(string)
    private_dns_enabled = bool
  }))
  default = []
}

variable "metastore_id" {
  type = string
  default = null
}

variable "enable_external_hms" {
  type = bool
  default = false
}

variable "create_legacy_resources" {
  type = bool
  default = false
}


variable "rds_password" {
  type = string
  default = "defaultpasswordpleasechange"
}

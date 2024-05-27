variable "tags" {
  type = map(string)
}

variable "catalog_name" {
  type = string
}

variable "workspace_name" {
  type = string
}

variable "prefix" {
  type = string // should be a randomized string  
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks Account ID"
}

variable "metastore_id" {
  type = string
}

variable "catalog_force_destroy" {
  type = bool
  default = false
}

variable "catalog_reuse_root_bucket" {
  type = bool
  default = true
}

variable "root_bucket_name" {
  type = string
}

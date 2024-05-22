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

variable "region" {
  type        = string
  description = "AWS region to deploy to"
  default     = "eu-central-1"
}

variable "meta_store_prefix" {
  type        = string
  description = "Metastore prefix"
  default     = "my-metastore"
}

variable "force_destroy" {
  type = bool
  default = true
}

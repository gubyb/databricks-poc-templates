variable "databricks_account_username" {
  type = string
  default = ""
}

variable "databricks_account_password" {
  type = string
  sensitive = true
  default = ""
}

variable "databricks_client_id" {
  type      = string
  sensitive = true
}

variable "databricks_client_secret" {
  type      = string
  sensitive = true
}

variable "auth_type" {
  type = string
  description = "Auth type"
  default = "basic"
  validation {
    condition = contains(["basic", "oauth-m2m"], var.auth_type)
    error_message = "Valid value is one of the following: basic, oauth-m2m."
  }
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

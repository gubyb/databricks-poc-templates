variable "crossaccount_role_name" {
  type        = string
  description = "Role that you've specified on https://accounts.cloud.databricks.com/#aws"
}

variable "tags" {
  type = map(string)
}

variable "prefix" {
  type = string // should be a randomized string  
}

variable "single_user_name" {
  type = string
}

variable "databricks_account_id" {
  type = string
}

variable "workspace_name" {
  type = string
}

variable "node_type" {
  type = string
  default = "r6id.xlarge"
}

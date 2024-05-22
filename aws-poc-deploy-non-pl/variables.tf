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
  default     = "ap-southeast-1"
}

variable "availability_zones" {
  type = list(string)
  description = "The 2 AZs to use"
  default = [ "ap-southeast-1a", "ap-southeast-1b" ]
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

variable "public_subnets_cidr" {
  type    = list(string)
  default = ["10.109.2.0/23"]
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
  }))
  default = []
}

variable "metastore_id" {
  type = string
}

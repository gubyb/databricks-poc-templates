variable "region" {
  type        = string
  description = "AWS region to deploy to"
  default     = "ap-southeast-1"
}

variable "tags" {
  default     = {}
  type        = map(string)
  description = "Optional tags to add to created resources"
}

variable "availability_zones" {
  type = list(string)
  description = "The 2 AZs to use"
  default = [ "ap-southeast-1a", "ap-southeast-1b" ]
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "prefix" {
  type        = string
  description = "Prefix to use"
  default     = "tf-modular-deploy"
}


variable "private_subnets_cidr" {
  type    = list(string)
  default = ["10.0.4.0/23", "10.0.6.0/23"]
}

variable "rds_password" {
  type        = string
  description = "rds admin pw"
}

variable "db_vpc_id" {
  type        = string
  description = "Databricks VPC ID"
}

variable "db_pl_subnet_id" {
  type        = string
  description = "Databricks subnet ID"
}

variable "db_pl_sg_id" {
  type        = string
  description = "Databricks sg ID"
}

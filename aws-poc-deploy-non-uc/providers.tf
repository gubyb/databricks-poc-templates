terraform {
  /*
  backend "s3" {
    bucket         = "tf-backend-bucket-haowang" # Replace this with your bucket name!
    key            = "global/s3-databricks-project/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "tf-backend-dynamodb-databricks-project" # Replace this with your DynamoDB table name!
    encrypt        = true
  }
  */
  required_providers {
    databricks = {
      source = "databricks/databricks"
      version = "1.29"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
}

// initialize provider in "MWS" mode to provision new workspace
provider "databricks" {
  alias         = "mws"
  host          = "https://accounts.cloud.databricks.com"
  account_id    = var.databricks_account_id

  # client_id     = var.databricks_client_id
  # client_secret = var.databricks_client_secret

  # Optional way of auth
  username   = var.databricks_account_username
  password   = var.databricks_account_password

  #auth_type = var.auth_type
}

locals {
  hosts = [for k, ws in module.workspace_collection : ws.workspace_url]
}

// Using workspace level scope to create catalog (does not matter which one used)
provider "databricks" {
  alias         = "created_workspace"
  host          = local.hosts[0]
  #account_id    = var.databricks_account_id

  # client_id     = var.databricks_client_id
  # client_secret = var.databricks_client_secret

  # Optional way of auth
  username   = var.databricks_account_username
  password   = var.databricks_account_password

  #auth_type = var.auth_type
}
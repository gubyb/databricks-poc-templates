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
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_sub_id
  tenant_id = var.azure_tenant_id
}

// initialize provider in "MWS" mode to provision new workspace
provider "databricks" {
  alias         = "account"
  host          = "https://accounts.azuredatabricks.net"
  account_id    = var.databricks_account_id
}

provider "databricks" {
  alias         = "created_workspace"
  host          = module.azure_resources.databricks_host
}

# locals {
#   hosts = [for k, ws in module.workspace_collection : ws.workspace_url]
# }

# // Using workspace level scope to create catalog (does not matter which one used)
# provider "databricks" {
#   alias         = "created_workspace"
#   host          = local.hosts[0]

#   client_id     = var.databricks_client_id
#   client_secret = var.databricks_client_secret
# }

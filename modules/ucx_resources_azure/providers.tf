terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      configuration_aliases = [ databricks ]
    }
    azurerm = {
      source = "hashicorp/azurerm"
      configuration_aliases = [ azurerm ]
    }
  }
}


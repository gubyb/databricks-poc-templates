module "azure_resources" {
  source    = "../modules/azure"
  providers = {
    azurerm        = azurerm
    databricks = databricks.mws
  }

  tags = var.tags
  region = var.region
  prefix = var.prefix
}
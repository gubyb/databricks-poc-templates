resource "azurerm_storage_account" "example" {
  name                     = "${replace(var.prefix, "-", "")}satf"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
  tags = var.tags
}

resource "azurerm_storage_container" "example" {
  name                     = "${replace(var.prefix, "-", "")}container"
  storage_account_id  = azurerm_storage_account.example.id
  container_access_type = "private"
}

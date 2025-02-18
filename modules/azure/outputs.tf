output "databricks_host" {
  value = "https://${azurerm_databricks_workspace.this.workspace_url}/"
}

output "storage_account" {
  value = azurerm_storage_account.example.name
}

output "storage_container" {
  value = azurerm_storage_container.example.name
}
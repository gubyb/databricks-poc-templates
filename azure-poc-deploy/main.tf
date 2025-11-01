module "azure_resources" {
  source    = "../modules/azure"
  providers = {
    azurerm        = azurerm
    databricks = databricks.account
  }

  tags = var.tags
  region = var.region
  prefix = var.prefix
}

# data "databricks_user" "admins" {
#   for_each = toset(var.admins)
#   provider = databricks.account

#   user_name = each.value
# }

# resource "databricks_permission_assignment" "add_user" {
#   for_each = data.databricks_user.admins
#   principal_id = each.value.id
#   permissions  = ["ADMIN"]
#   provider     = databricks.created_workspace
# }

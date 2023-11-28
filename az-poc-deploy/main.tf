data "databricks_metastores" "all" {
  provider = databricks.accounts
}

output "all_metastores" {
  value = data.databricks_metastores.all.ids
}

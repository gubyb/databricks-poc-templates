data "databricks_group" "users" {
  display_name = "users"
}

resource "databricks_entitlements" "workspace-users" {
  group_id                   = data.databricks_group.users.id
  allow_cluster_create       = true
  allow_instance_pool_create = true
  workspace_access = true
}

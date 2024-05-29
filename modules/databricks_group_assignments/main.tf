resource "databricks_mws_permission_assignment" "add_groups" {
  workspace_id = var.workspace_id
  principal_id = var.group_id
  permissions  = [var.group_type]
}

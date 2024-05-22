resource "databricks_notebook" "workspace_shared_test_hms_stuff_managed_775639255079334" {
  source = "${path.module}/notebooks/Workspace/Shared/test_hms_stuff_managed_775639255079334.py"
  path   = "/Workspace/Shared/test_hms_stuff_managed"
}
resource "databricks_notebook" "workspace_shared_test_hms_stuff_external_775639255079376" {
  source = "${path.module}/notebooks/Workspace/Shared/test_hms_stuff_external_775639255079376.py"
  path   = "/Workspace/Shared/test_hms_stuff_external"
}

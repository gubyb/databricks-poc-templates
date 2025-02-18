resource "databricks_notebook" "workspace_shared_test_hms_stuff_managed" {
  source = "${path.module}/notebooks/Workspace/Shared/test_hms_stuff_managed.py"
  path   = "/Workspace/Shared/test_hms_stuff_managed"
}
resource "databricks_notebook" "workspace_shared_test_hms_stuff_external" {
  source = "${path.module}/notebooks/Workspace/Shared/test_hms_stuff_external.py"
  path   = "/Workspace/Shared/test_hms_stuff_external"
}

resource "databricks_notebook" "submit_run" {
  source = "${path.module}/notebooks/Workspace/Shared/submit_run.py"
  path   = "/Workspace/Shared/submit_run"
}

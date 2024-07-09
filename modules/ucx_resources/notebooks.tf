resource "databricks_notebook" "workspace_shared_test_hms_stuff_managed" {
  source = "${path.module}/notebooks/Workspace/Shared/test_hms_stuff_managed.py"
  path   = "/Workspace/Shared/test_hms_stuff_managed"
}
resource "databricks_notebook" "workspace_shared_test_hms_stuff_external" {
  source = "${path.module}/notebooks/Workspace/Shared/test_hms_stuff_external.py"
  path   = "/Workspace/Shared/test_hms_stuff_external"
}

resource "databricks_notebook" "test_instance_profile" {
  source = "${path.module}/notebooks/Workspace/Shared/test_instance_profile.py"
  path   = "/Workspace/Shared/test_instance_profile"
}

resource "databricks_notebook" "test_boto3" {
  source = "${path.module}/notebooks/Workspace/Shared/test_boto3.py"
  path   = "/Workspace/Shared/test_boto3"
}
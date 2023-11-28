resource "databricks_metastore" "this" {
  provider      = databricks.mws
  name          = "${var.meta_store_prefix}-${var.region}"
  region        = var.region
  force_destroy = var.force_destroy
}
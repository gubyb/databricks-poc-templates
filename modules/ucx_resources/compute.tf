resource "databricks_cluster" "test_no_uc_0520_121619_7fevb76h" {
  spark_version      = "14.3.x-scala2.12"
  runtime_engine     = "STANDARD"
  num_workers        = 1
  node_type_id       = "r6id.xlarge"
  data_security_mode = "NONE"
  cluster_name       = "test_no_uc"
  aws_attributes {
    zone_id                = "auto"
    spot_bid_price_percent = 100
    first_on_demand        = 1
    availability           = "SPOT_WITH_FALLBACK"
  }
  autotermination_minutes = 10
}

resource "databricks_sql_endpoint" "ucx_wh" {
  name             = "Endpoint for UCX"
  cluster_size     = "2X-Small"
  max_num_clusters = 1
  auto_stop_mins = 10
  warehouse_type = "PRO"
  
}
# resource "databricks_job" "test_create_tables" {
#   task {
#     task_key = "external"
#     run_if   = "ALL_SUCCESS"
#     notification_settings {
#     }
#     notebook_task {
#       notebook_path = databricks_notebook.workspace_shared_test_hms_stuff_external.id
#     }
#     job_cluster_key = "test_create_tables"
#   }
#   task {
#     task_key = "managed"
#     run_if   = "ALL_SUCCESS"
#     notification_settings {
#     }
#     notebook_task {
#       notebook_path = databricks_notebook.workspace_shared_test_hms_stuff_managed.id
#     }
#     job_cluster_key = "test_create_tables"
#   }
#   queue {
#     enabled = true
#   }
#   name = "test_create_tables"
#   job_cluster {
#     new_cluster {
#       spark_version      = "14.3.x-scala2.12"
#       runtime_engine     = "STANDARD"
#       num_workers        = 2
#       node_type_id       = "r6id.xlarge"
#       data_security_mode = "SINGLE_USER"
#       aws_attributes {
#         zone_id                = "ap-southeast-1b"
#         spot_bid_price_percent = 100
#         first_on_demand        = 1
#         availability           = "SPOT_WITH_FALLBACK"
#       }
#     }
#     job_cluster_key = "test_create_tables"
#   }
#   email_notifications {
#   }
# }

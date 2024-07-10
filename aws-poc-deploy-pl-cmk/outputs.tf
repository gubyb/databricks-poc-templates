output "databricks_hosts" {
  value = tomap({
    for k, ws in module.workspace_collection : k => ws.workspace_url
  })
}

# output "endpoint_service_name" {
#     value = "${module.external_hms.endpoint_service_name}"
# }

# output "rds_endpoint_name" {
#     value = "${module.external_hms.rds_endpoint_name}"
# }

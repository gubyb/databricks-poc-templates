output "endpoint_service_name" {
  value = aws_vpc_endpoint_service.rds_endpoint_service.service_name
}

output "rds_endpoint_name" {
  value = aws_db_instance.default.address
}


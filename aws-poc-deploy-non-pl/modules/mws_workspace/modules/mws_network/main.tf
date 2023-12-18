data "aws_availability_zones" "available" {}

# Private subnets
resource "aws_subnet" "private_subnets" {
  count                   = length(var.private_subnet_pair)
  vpc_id                  = var.existing_vpc_id
  cidr_block              = var.private_subnet_pair[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = var.tags
  tags_all = var.tags
}

# Private route table
resource "aws_route_table" "private_route_tables" {
  count  = length(var.private_subnet_pair)
  vpc_id = var.existing_vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.aws_nat_gateway_id
  }
  tags = var.tags
  tags_all = var.tags
}

# Private route table association
resource "aws_route_table_association" "private_route_table_associations" {
  count          = length(var.private_subnet_pair)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_tables[count.index].id
}

# create service endpoints for AWS services
# S3 endpoint
resource "aws_vpc_endpoint" "s3" {
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_id = var.existing_vpc_id
  route_table_ids = aws_route_table.private_route_tables[*].id
  tags = var.tags
  tags_all = var.tags
  vpc_endpoint_type = "Gateway"
}

# Kinesis endpoint
resource "aws_vpc_endpoint" "kinesis" {
  service_name = "com.amazonaws.${var.region}.kinesis-streams"
  vpc_id = var.existing_vpc_id
  subnet_ids = aws_subnet.private_subnets[*].id
  tags = var.tags
  tags_all = var.tags
  vpc_endpoint_type = "Interface"
  security_group_ids = var.security_group_ids
  private_dns_enabled = true
}

# STS endpoint
resource "aws_vpc_endpoint" "sts" {
  service_name = "com.amazonaws.${var.region}.sts"
  vpc_id = var.existing_vpc_id
  subnet_ids = aws_subnet.private_subnets[*].id
  tags = var.tags
  tags_all = var.tags
  vpc_endpoint_type = "Interface"
  security_group_ids = var.security_group_ids
  private_dns_enabled = true
}

resource "databricks_mws_networks" "mwsnetwork" {
  account_id         = var.databricks_account_id
  network_name       = "${var.prefix}-network"
  vpc_id             = var.existing_vpc_id
  subnet_ids         = [aws_subnet.private_subnets.0.id, aws_subnet.private_subnets.1.id]
  security_group_ids = var.security_group_ids
}

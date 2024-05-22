resource "aws_security_group" "privatelink" {
  vpc_id = aws_vpc.mainvpc.id

  ingress {
    description     = "Inbound rules"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.sg.id]
  }

  ingress {
    description     = "Inbound rules"
    from_port       = 6666
    to_port         = 6666
    protocol        = "tcp"
    security_groups = [aws_security_group.sg.id]
  }

  egress {
    description     = "Outbound rules"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.sg.id]
  }

  egress {
    description     = "Outbound rules"
    from_port       = 6666
    to_port         = 6666
    protocol        = "tcp"
    security_groups = [aws_security_group.sg.id]
  }

  tags = merge(var.tags, {
     Name = "${local.prefix}-privatelink-sg"
  })

  tags_all = var.tags
  
}

resource "aws_vpc_endpoint" "backend_rest" {
  vpc_id              = aws_vpc.mainvpc.id
  service_name        = var.workspace_vpce_service
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.privatelink.id]
  subnet_ids          = aws_subnet.privatelink[*].id
  private_dns_enabled = true // try to directly set this to true in the first apply
  depends_on          = [aws_subnet.privatelink]

  tags = merge(var.tags, {
     Name = "${local.prefix}-databricks-backend-rest"
  })

  tags_all = var.tags
}

resource "aws_vpc_endpoint" "backend_relay" {
  vpc_id              = aws_vpc.mainvpc.id
  service_name        = var.relay_vpce_service
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.privatelink.id]
  subnet_ids          = aws_subnet.privatelink[*].id
  private_dns_enabled = true
  depends_on          = [aws_subnet.privatelink]

  tags = merge(var.tags, {
     Name = "${local.prefix}-databricks-backend-relay"
  })

  tags_all = var.tags
}

// from official guide
resource "databricks_mws_vpc_endpoint" "backend_rest_vpce" {
  provider            = databricks.mws
  account_id          = var.databricks_account_id
  aws_vpc_endpoint_id = aws_vpc_endpoint.backend_rest.id
  vpc_endpoint_name   = "${local.prefix}-vpc-backend-${aws_vpc.mainvpc.id}"
  region              = var.region
  depends_on          = [aws_vpc_endpoint.backend_rest]
}

resource "databricks_mws_vpc_endpoint" "relay" {
  provider            = databricks.mws
  account_id          = var.databricks_account_id
  aws_vpc_endpoint_id = aws_vpc_endpoint.backend_relay.id
  vpc_endpoint_name   = "${local.prefix}-vpc-relay-${aws_vpc.mainvpc.id}"
  region              = var.region
  depends_on          = [aws_vpc_endpoint.backend_relay]
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "mainvpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.prefix}-rds-vpc"
  })

  tags_all = var.tags
}

# Private subnets collection for Private Link (VPC endpoints), default 1
resource "aws_subnet" "private_subnet" {
  count                   = length(var.private_subnets_cidr)
  vpc_id                  = aws_vpc.mainvpc.id
  cidr_block              = var.private_subnets_cidr[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false // explicit private subnet

  tags = merge(var.tags, {
    Name = "${var.prefix}-${aws_vpc.mainvpc.id}-rds-private-subnet"
  })

  tags_all = var.tags
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = aws_subnet.private_subnet[*].id

  tags = merge(var.tags, {
    Name = "${var.prefix}-rds-subnets"
  })

  tags_all = var.tags
}


resource "aws_route_table" "private_subnet_rt" {
  vpc_id = aws_vpc.mainvpc.id

  tags = merge(var.tags, {
    Name = "${var.prefix}-rds-local-route-tbl"
  })

  tags_all = var.tags
}

resource "aws_route_table_association" "dataplane_vpce_rtb" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_subnet_rt.id
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.mainvpc.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.mainvpc.id

  name        = "databricks-rds-security-group-${var.prefix}"
  description = "databricks vpc security group for ${var.prefix}"

  # Add any additional ingress/egress rules as needed
  ingress {
    description     = "Inbound rules"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_default_security_group.default.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.prefix}-rds-sg"
  })

  tags_all = var.tags
}

resource "aws_lb_target_group" "rds_ip_target_group" {
  name        = "${var.prefix}-rds-target-grp"
  port        = 3306
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.mainvpc.id

  tags = merge(var.tags, {
    Name = "${var.prefix}-rds-target-grp"
  })

  tags_all = var.tags
}

# Will change over time, need to implement lambda to update
data "dns_a_record_set" "rds_ip" {
  host     = aws_db_instance.default.address
}

resource "aws_lb_target_group_attachment" "rds_target_group_attachment" {

  target_group_arn = aws_lb_target_group.rds_ip_target_group.arn
  target_id        = data.dns_a_record_set.rds_ip.addrs[0]

  lifecycle {
    ignore_changes = [target_id]
  }
  depends_on = [aws_lb_target_group.rds_ip_target_group]
}


resource "aws_lb" "rds_nlb" {
  name                             = "${var.prefix}-rds-nlb"
  internal                         = true
  load_balancer_type               = "network"
  subnets                          = aws_subnet.private_subnet[*].id
  enable_cross_zone_load_balancing = false
  security_groups = [aws_default_security_group.default.id]
  tags = merge(var.tags, {
    Name = "${var.prefix}-rds-nlb"
  })

  tags_all = var.tags
}

resource "aws_lb_listener" "rds_nlb_listener" {
  load_balancer_arn = aws_lb.rds_nlb.arn
  port              = 3306
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rds_ip_target_group.arn
  }

  tags = merge(var.tags, {
    Name = "${var.prefix}-rds-nlb-listener"
  })

  tags_all = var.tags
}

resource "aws_vpc_endpoint_service" "rds_endpoint_service" {
  acceptance_required        = true
  network_load_balancer_arns = [aws_lb.rds_nlb.arn]

  tags = merge(var.tags, {
    Name = "${var.prefix}-rds-endpoint-service"
  })

  tags_all = var.tags
}

#Optional, allow Databricks to connect with serverless PL 
resource "aws_vpc_endpoint_service_allowed_principal" "databricks_serverless_allowed_principal" {
  vpc_endpoint_service_id = aws_vpc_endpoint_service.rds_endpoint_service.id
  principal_arn           = "arn:aws:iam::565502421330:role/private-connectivity-role-${var.region}"
}

resource "aws_vpc_endpoint" "nlb_endpoint" {
  vpc_id              = var.db_vpc_id
  service_name        = aws_vpc_endpoint_service.rds_endpoint_service.service_name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [var.db_pl_sg_id]
  subnet_ids          = [var.db_pl_subnet_id]
  private_dns_enabled = false

  tags = merge(var.tags, {
    Name = "${var.prefix}-rds-nlb-endpoint"
  })

  tags_all = var.tags
}

resource "aws_vpc_endpoint_connection_accepter" "accept_db_nlb_endpoint" {
  vpc_endpoint_service_id = aws_vpc_endpoint_service.rds_endpoint_service.id
  vpc_endpoint_id         = aws_vpc_endpoint.nlb_endpoint.id
}

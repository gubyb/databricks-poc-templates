resource "random_string" "naming" {
  special = false
  upper   = false
  length  = 6
}

locals {
  prefix              = var.prefix
  sg_egress_ports     = concat([443, 3306, 6666], range(8443, 8451))
  sg_ingress_protocol = ["tcp", "udp"]
  sg_egress_protocol  = ["tcp", "udp"]
  workspace_confs = var.workspaces
  private_subnet_cidrs = flatten([for workspace_conf in local.workspace_confs : [
    workspace_conf.private_subnet_pair.subnet1_cidr,
    workspace_conf.private_subnet_pair.subnet2_cidr
    ]
  ])
}

// for each VPC, you should create workspace_collection
module "workspace_collection" {
  for_each = { for each in local.workspace_confs : each.workspace_name => each }

  providers = {
    databricks = databricks.mws
    aws        = aws
  }

  source                = "./modules/mws_workspace"
  databricks_account_id = var.databricks_account_id
  credentials_id        = databricks_mws_credentials.this.credentials_id
  prefix                = each.value.prefix
  region                = var.region
  availability_zones    = var.availability_zones
  workspace_name        = each.value.workspace_name
  tags                  = each.value.tags
  existing_vpc_id       = aws_vpc.mainvpc.id
  nat_gateways_id       = aws_nat_gateway.nat_gateways[0].id
  security_group_ids    = [aws_security_group.sg.id]
  private_subnet_pair   = [each.value.private_subnet_pair.subnet1_cidr, each.value.private_subnet_pair.subnet2_cidr]
  root_bucket_name      = each.value.root_bucket_name
  workspace_admins      = each.value.workspace_admins
  metastore_id          = var.metastore_id
  managed_storage_cmk   = databricks_mws_customer_managed_keys.managed_storage.customer_managed_key_id
  workspace_storage_cmk = databricks_mws_customer_managed_keys.workspace_storage.customer_managed_key_id
  private_dns_enabled   = each.value.private_dns_enabled
  depends_on = [
    databricks_mws_vpc_endpoint.relay,
    databricks_mws_vpc_endpoint.backend_rest_vpce
  ]
}

module "uc_catalogs" {
  for_each = { for each in local.workspace_confs : each.workspace_name => each }

  providers = {
    databricks = databricks.created_workspace
    aws        = aws
  }

  source                = "./modules/mws_uc_catalog"
  tags = each.value.tags
  catalog_name = "${each.value.workspace_name}-catalog"
  workspace_name = each.value.workspace_name
  prefix = each.value.prefix
  databricks_account_id = var.databricks_account_id
  metastore_id = var.metastore_id
  catalog_force_destroy = true
  catalog_reuse_root_bucket = true
  root_bucket_name = each.value.root_bucket_name

  depends_on = [
    module.workspace_collection
  ]
}

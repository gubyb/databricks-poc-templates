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
  workspace_confs     = var.workspaces
  private_subnet_cidrs = flatten([for workspace_conf in local.workspace_confs : [
    workspace_conf.private_subnet_pair.subnet1_cidr,
    workspace_conf.private_subnet_pair.subnet2_cidr
    ]
  ])
  metastore_admin_group = distinct(var.metastore_admins)
  groups = [
    {
      name = "group_1",
      type = "USER"
    },
    {
      name = "group_2",
      type = "USER"
    },
    {
      name = "group_3",
      type = "USER"
    },
    {
      name = "group_4",
      type = "USER"
    }
  ]
}

resource "databricks_group" "metastore_admin_group" {
  provider     = databricks.mws
  display_name = "${local.prefix}-metastore-admins"
}

data "databricks_user" "metastore_admin_users" {
  provider = databricks.mws
  for_each = toset(local.metastore_admin_group)

  user_name = each.value
}

data "databricks_service_principal" "metastore_admin_spn" {
  provider       = databricks.mws
  application_id = var.databricks_client_id
}

resource "databricks_group_member" "metastore_admin_group_users" {
  for_each  = data.databricks_user.metastore_admin_users
  provider  = databricks.mws
  group_id  = databricks_group.metastore_admin_group.id
  member_id = each.value.id
}

resource "databricks_group_member" "metastore_admin_group_spn" {
  provider  = databricks.mws
  group_id  = databricks_group.metastore_admin_group.id
  member_id = data.databricks_service_principal.metastore_admin_spn.id
}

resource "databricks_metastore" "metastore" {
  count = var.metastore_id == null ? 1 : 0

  provider      = databricks.mws
  name          = "${local.prefix}-metastore"
  owner         = databricks_group.metastore_admin_group.display_name
  region        = var.region
  force_destroy = true
}

// for each VPC, you should create workspace_collection
module "workspace_collection" {
  for_each = { for each in local.workspace_confs : each.workspace_name => each }

  providers = {
    databricks = databricks.mws
    aws        = aws
  }

  source                = "../modules/mws_workspace"
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
  metastore_id          = var.metastore_id == null ? databricks_metastore.metastore[0].id : var.metastore_id
  managed_storage_cmk   = databricks_mws_customer_managed_keys.managed_storage.customer_managed_key_id
  workspace_storage_cmk = databricks_mws_customer_managed_keys.workspace_storage.customer_managed_key_id
  private_dns_enabled   = each.value.private_dns_enabled
  databricks_client_id = var.databricks_client_id
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

  source                    = "../modules/mws_uc_catalog"
  tags                      = each.value.tags
  catalog_name              = "${each.value.workspace_name}-catalog"
  workspace_name            = each.value.workspace_name
  prefix                    = each.value.prefix
  databricks_account_id     = var.databricks_account_id
  metastore_id              = var.metastore_id == null ? databricks_metastore.metastore[0].id : var.metastore_id
  catalog_force_destroy     = true
  catalog_reuse_root_bucket = false
  root_bucket_name          = each.value.root_bucket_name

  depends_on = [
    module.workspace_collection, databricks_group.metastore_admin_group
  ]
}

module "groups" {
  for_each = { for each in local.groups : each.name => each }

  providers = {
    databricks = databricks.mws
  }

  source  = "../modules/databricks_groups"

  group_name = each.value.name
}

locals {
  workspace_assingments = distinct(flatten([
    for workspace_conf in local.workspace_confs : [
      for group in local.groups : {
        workspace_conf = workspace_conf
        group    = group
      }
    ]
  ]))
}

module "workspace_assignments" {
  for_each      = { for entry in local.workspace_assingments: "${entry.workspace_conf.workspace_name}_${entry.group.name}" => entry }

  source  = "../modules/databricks_group_assignments"

  providers = {
    databricks = databricks.mws
  }

  group_id   = module.groups[each.value.group.name].group_id
  group_type = each.value.group.type
  workspace_id = module.workspace_collection[each.value.workspace_conf.workspace_name].workspace_id

  depends_on = [ module.groups ]
}

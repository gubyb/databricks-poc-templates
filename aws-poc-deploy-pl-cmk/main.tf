resource "random_string" "naming" {
  special = false
  upper   = false
  length  = 6
}

locals {
  prefix              = var.prefix
  workspace_confs     = var.workspaces
  private_subnet_cidrs = flatten([for workspace_conf in local.workspace_confs : [
    workspace_conf.private_subnet_pair.subnet1_cidr,
    workspace_conf.private_subnet_pair.subnet2_cidr
    ]
  ])
  metastore_admin_group = distinct(var.metastore_admins)
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

// from official guide
resource "databricks_mws_vpc_endpoint" "backend_rest_vpce" {
  provider            = databricks.mws
  account_id          = var.databricks_account_id
  aws_vpc_endpoint_id = module.aws_resources.backend_rest_pe
  vpc_endpoint_name   = "${local.prefix}-vpc-backend"
  region              = var.region
}

resource "databricks_mws_vpc_endpoint" "relay" {
  provider            = databricks.mws
  account_id          = var.databricks_account_id
  aws_vpc_endpoint_id = module.aws_resources.backend_relay_pe
  vpc_endpoint_name   = "${local.prefix}-vpc-relay"
  region              = var.region
}

// create AWS resources
module "aws_resources" {
  source                = "../modules/aws"
  providers = {
    aws        = aws
    databricks = databricks.mws
  }

  databricks_account_id = var.databricks_account_id
  region = var.region
  availability_zones = var.availability_zones
  prefix = var.prefix
  tags = var.tags
  vpc_cidr = var.vpc_cidr
  public_subnets_cidr = var.public_subnets_cidr
  privatelink_subnets_cidr = var.privatelink_subnets_cidr
  workspace_vpce_service = var.workspace_vpce_service
  relay_vpce_service = var.relay_vpce_service
}

// Managed Key Configuration
resource "databricks_mws_customer_managed_keys" "managed_storage" {
  provider         = databricks.mws
  account_id = var.databricks_account_id
  aws_key_info {
    key_arn   = module.aws_resources.aws_kms_key_manage_storage_arn
    key_alias = module.aws_resources.aws_kms_key_manage_storage_key_alias
  }
  use_cases = ["MANAGED_SERVICES"]
}

// Workspace Storage Key Configuration
resource "databricks_mws_customer_managed_keys" "workspace_storage" {
  provider         = databricks.mws
  account_id = var.databricks_account_id
  aws_key_info {
    key_arn   = module.aws_resources.aws_kms_key_workspace_storage_arn
    key_alias = module.aws_resources.aws_kms_key_workspace_storage_key_alias
  }
  use_cases = ["STORAGE"]
}

resource "databricks_mws_credentials" "this" {
  provider         = databricks.mws
  role_arn         = module.aws_resources.cross_account_role
  credentials_name = "${local.prefix}-creds"
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
  existing_vpc_id       = module.aws_resources.vpc_id
  nat_gateways_id       = module.aws_resources.nat_gateway_id
  security_group_ids    = [module.aws_resources.aws_sg_id]
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

module "ucx_resources" {
  # count  = var.create_legacy_resources ? 1 : 0 need to fix
  for_each = { for each in local.workspace_confs : each.workspace_name => each }

  providers = {
    databricks = databricks.created_workspace
    aws        = aws
  }

  source = "../modules/ucx_resources"

  crossaccount_role_name = module.aws_resources.cross_account_role_name
  tags = var.tags
  prefix = var.prefix
  single_user_name = each.value.workspace_admins[0]
  workspace_name = each.key
  databricks_account_id = var.databricks_account_id

  depends_on = [
    module.uc_catalogs
  ]
}

module "external_hms" {
  count  = var.enable_external_hms ? 1 : 0
  providers = {
    databricks = databricks.created_workspace
    aws        = aws
  }

  source = "../modules/external_hms"

  tags = var.tags
  region = var.region
  availability_zones = var.availability_zones
  vpc_cidr = "10.0.0.0/16" #Default value
  prefix = var.prefix
  private_subnets_cidr = ["10.0.4.0/23", "10.0.6.0/23"] #Default value
  rds_password = var.rds_password
  db_pl_subnet_id = module.aws_resources.pl_subnet_id
  db_vpc_id = module.aws_resources.vpc_id
  db_pl_sg_id = module.aws_resources.aws_pl_sg_id
}
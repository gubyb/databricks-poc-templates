module "my_mws_network" {
  source                = "./modules/mws_network"
  databricks_account_id = var.databricks_account_id
  aws_nat_gateway_id    = var.nat_gateways_id
  existing_vpc_id       = var.existing_vpc_id
  security_group_ids    = var.security_group_ids
  region                = var.region
  private_subnet_pair   = var.private_subnet_pair
  availability_zones    = var.availability_zones
  prefix                = "${var.prefix}-network"
  relay_vpce_id         = var.relay_vpce_id
  rest_vpce_id          = var.rest_vpce_id
  tags                  = var.tags
}

module "my_root_bucket" {
  source                = "./modules/mws_storage"
  databricks_account_id = var.databricks_account_id
  region                = var.region
  root_bucket_name      = var.root_bucket_name
  tags                  = var.tags
}


resource "databricks_mws_private_access_settings" "pas" {
  account_id                   = var.databricks_account_id
  private_access_settings_name = "Private Access Settings for ${var.prefix}"
  region                       = var.region
  public_access_enabled        = true
  private_access_level         = "ACCOUNT" // a fix for recent changes - 202209
}


resource "databricks_mws_workspaces" "this" {
  account_id                 = var.databricks_account_id
  aws_region                 = var.region
  workspace_name             = var.workspace_name
  private_access_settings_id = databricks_mws_private_access_settings.pas.private_access_settings_id
  pricing_tier               = "ENTERPRISE"

  # deployment_name = local.prefix

  credentials_id           = var.credentials_id
  storage_configuration_id = module.my_root_bucket.storage_configuration_id
  network_id               = module.my_mws_network.network_id

  depends_on = [module.my_mws_network, module.my_root_bucket]
}

resource "databricks_metastore_assignment" "metastore_assignment" {
  metastore_id = var.metastore_id
  workspace_id = databricks_mws_workspaces.this.workspace_id
}

data "databricks_user" "workspace_admins" {
  for_each = toset(var.workspace_admins)

  user_name = each.value
}

resource "databricks_group" "workspace_admin_group" {
  display_name = "${var.workspace_name}-admins"
}

resource "databricks_group_member" "group_members" {
  for_each = data.databricks_user.workspace_admins

  group_id = databricks_group.workspace_admin_group.id
  member_id = each.value.id
}

resource "databricks_mws_permission_assignment" "admin_assignments" {
  for_each = data.databricks_user.workspace_admins

  workspace_id = databricks_mws_workspaces.this.workspace_id
  principal_id = each.value.id
  permissions  = ["ADMIN"]

  depends_on = [databricks_metastore_assignment.metastore_assignment]
}

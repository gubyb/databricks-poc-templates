resource "aws_s3_bucket" "catalog_root_bucket" {
  count = var.catalog_reuse_root_bucket ? 0 : 1

  bucket        = "${var.catalog_name}-bucket"
  force_destroy = true
  tags          = var.tags
  tags_all      = var.tags
}

data "aws_s3_bucket" "ws_root_bucket" {
  bucket = var.root_bucket_name
}

resource "aws_s3_bucket_public_access_block" "root_storage_bucket" {
  count = var.catalog_reuse_root_bucket ? 0 : 1

  bucket             = aws_s3_bucket.catalog_root_bucket[0].id
  block_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls = true
  depends_on         = [aws_s3_bucket.catalog_root_bucket]
}

resource "aws_s3_bucket_versioning" "external_versioning" {
  count = var.catalog_reuse_root_bucket ? 0 : 1
  bucket = aws_s3_bucket.catalog_root_bucket[0].id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_iam_policy" "external_data_access" {
  count = var.catalog_reuse_root_bucket ? 0 : 1
  // Terraform's "jsonencode" function converts a
  // Terraform expression's result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${aws_s3_bucket.catalog_root_bucket[0].id}-access"
    Statement = [
      {
        "Action" : [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        "Resource" : [
          aws_s3_bucket.catalog_root_bucket[0].arn,
          "${aws_s3_bucket.catalog_root_bucket[0].arn}/*"
        ],
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "sts:AssumeRole"
        ],
        "Resource" : [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.prefix}-uc-access"
        ],
        "Effect" : "Allow"
      }
    ]
  })
  tags = var.tags
  tags_all = var.tags
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "passrole_for_uc" {
  count = var.catalog_reuse_root_bucket ? 0 : 1
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL"]
      type        = "AWS"
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.databricks_account_id]
    }
  }
  statement {
    sid     = "ExplicitSelfRoleAssumption"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.prefix}-uc-access"]
    }
  }
}

resource "aws_iam_role" "external_data_access" {
  count = var.catalog_reuse_root_bucket ? 0 : 1
  name                = "${var.prefix}-uc-access"
  assume_role_policy  = data.aws_iam_policy_document.passrole_for_uc[0].json
  managed_policy_arns = [aws_iam_policy.external_data_access[0].arn]
  tags = var.tags
  tags_all = var.tags
}

data "databricks_group" "workspace_admin_group" {
  display_name = "${var.workspace_name}-admins"
}

resource "databricks_storage_credential" "external" {
  count = var.catalog_reuse_root_bucket ? 0 : 1
  name     = aws_iam_role.external_data_access[0].name
  aws_iam_role {
    role_arn = aws_iam_role.external_data_access[0].arn
  }
  comment = "Managed by TF"

  owner = data.databricks_group.workspace_admin_group.display_name
}

resource "databricks_grants" "external_all_privileges" {
  storage_credential = databricks_storage_credential.external[0].id
  grant {
    principal  = data.databricks_group.workspace_admin_group.display_name
    privileges = ["ALL_PRIVILEGES"]
  }
}

resource "time_sleep" "wait" {
  count = var.catalog_reuse_root_bucket ? 0 : 1
  depends_on = [
    databricks_storage_credential.external
  ]
  create_duration = "60s"
}

// External Location
resource "databricks_external_location" "data_example" {
  count = var.catalog_reuse_root_bucket ? 0 : 1
  name            = "${var.catalog_name}-${var.prefix}-external-location"
  url             = "s3://${aws_s3_bucket.catalog_root_bucket[0].id}/"
  credential_name = databricks_storage_credential.external[0].id
  comment         = "Managed by TF"
  force_destroy   = var.catalog_force_destroy
  owner = data.databricks_group.workspace_admin_group.display_name
  #owner = data.databricks_group.workspace_admin_group.display_name
  depends_on         = [time_sleep.wait]
}

# resource "databricks_grants" "external_loc_all_privileges" {
#   external_location = databricks_external_location.data_example[0].id
#   grant {
#     principal  = data.databricks_group.workspace_admin_group.display_name
#     privileges = ["ALL_PRIVILEGES"]
#   }
# }

locals {
  poc_schemas = ["bronze", "silver", "gold", "sandbox"]
}

resource "databricks_catalog" "sandbox" {
  metastore_id = var.metastore_id
  name         = "${var.catalog_name}-${var.prefix}-catalog"
  comment      = "This catalog is managed by terraform"
  properties = var.tags

  force_destroy = var.catalog_force_destroy
  storage_root  = var.catalog_reuse_root_bucket ? null : "${databricks_external_location.data_example[0].url}catalogs"
  depends_on = [databricks_external_location.data_example]
}

resource "databricks_schema" "poc_schemas" {
  count  = length(local.poc_schemas)

  catalog_name  = databricks_catalog.sandbox.name
  name          = local.poc_schemas[count.index]
  properties = var.tags
  comment = "This schema is managed by terraform"
  force_destroy = true
}

resource "databricks_system_schema" "system_schema_access" {
  schema = "access"
}

resource "databricks_system_schema" "system_schema_compute" {
  schema = "compute"
}

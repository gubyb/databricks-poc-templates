resource "aws_s3_bucket" "catalog_root_bucket" {
  bucket        = "${var.catalog_name}-bucket"
  force_destroy = true
  tags          = var.tags
  tags_all      = var.tags
}

resource "aws_s3_bucket_public_access_block" "root_storage_bucket" {
  bucket             = aws_s3_bucket.catalog_root_bucket.id
  block_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls = true
  depends_on         = [aws_s3_bucket.catalog_root_bucket]
}

resource "aws_s3_bucket_versioning" "external_versioning" {
  bucket = aws_s3_bucket.catalog_root_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_iam_policy" "external_data_access" {
  // Terraform's "jsonencode" function converts a
  // Terraform expression's result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${aws_s3_bucket.catalog_root_bucket.id}-access"
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
          aws_s3_bucket.catalog_root_bucket.arn,
          "${aws_s3_bucket.catalog_root_bucket.arn}/*"
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
  name                = "${var.prefix}-uc-external-location"
  assume_role_policy  = data.aws_iam_policy_document.passrole_for_uc.json
  managed_policy_arns = [aws_iam_policy.external_data_access.arn]
  tags = var.tags
  tags_all = var.tags
}

resource "databricks_storage_credential" "external" {
  name     = aws_iam_role.external_data_access.name
  aws_iam_role {
    role_arn = aws_iam_role.external_data_access.arn
  }
  comment = "Managed by TF"
}

resource "time_sleep" "wait" {
  depends_on = [
    databricks_storage_credential.external
  ]
  create_duration = "20s"
}

// External Location
resource "databricks_external_location" "data_example" {
  name            = "${var.catalog_name}-${var.prefix}-external-location"
  url             = "s3://${aws_s3_bucket.catalog_root_bucket.id}/"
  credential_name = databricks_storage_credential.external.id
  comment         = "Managed by TF"
  force_destroy   = var.catalog_force_destroy

  depends_on         = [time_sleep.wait]
}

resource "databricks_catalog" "sandbox" {
  metastore_id = var.metastore_id
  name         = "${var.catalog_name}-${var.prefix}-catalog"
  comment      = "This catalog is managed by terraform"
  properties = var.tags

  force_destroy = var.catalog_force_destroy
  storage_root  = "s3://${aws_s3_bucket.catalog_root_bucket.id}/${var.catalog_name}-${var.prefix}-catalog"
  owner = "account users" # Giving account users ownership for POC purpose

  depends_on = [databricks_external_location.data_example]
}

locals {
  poc_schemas = ["bronze", "silver", "gold", "sandbox"]
}

resource "databricks_schema" "poc_schemas" {
  count  = length(local.poc_schemas)

  catalog_name  = databricks_catalog.sandbox.name
  name          = local.poc_schemas[count.index]
  properties = var.tags
  comment = "This schema is managed by terraform"
  owner = "account users" # Giving account users ownership for POC purpose
  force_destroy = true
}

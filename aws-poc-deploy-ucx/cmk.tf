data "aws_caller_identity" "current" {}

locals {
  cmk_admin_value = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
}

resource "aws_kms_key" "workspace_storage" {
  description = "KMS key for databricks workspace storage"
  policy = jsonencode({ Version : "2012-10-17",
    "Id" : "key-policy-workspace-storage",
    Statement : [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [local.cmk_admin_value]
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "Allow Databricks to use KMS key for DBFS",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::414351767826:root"
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "aws:PrincipalTag/DatabricksAccountId" : "${var.databricks_account_id}"
          }
        }
      },
      {
        "Sid" : "Allow Databricks to use KMS key for EBS",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "${aws_iam_role.cross_account_role.arn}"
        },
        "Action" : [
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ],
        "Resource" : "*",
        "Condition" : {
          "ForAnyValue:StringLike" : {
            "kms:ViaService" : "ec2.*.amazonaws.com"
          }
        }
      }
    ]
    }
  )
  depends_on = [aws_iam_role.cross_account_role]
}

resource "aws_kms_alias" "workspace_storage_key_alias" {
  name          = "alias/${var.prefix}-workspace-storage-key-alias"
  target_key_id = aws_kms_key.workspace_storage.id
}

## CMK for Managed Storage

resource "aws_kms_key" "managed_storage" {
  description = "KMS key for managed storage"
  policy = jsonencode({ Version : "2012-10-17",
    "Id" : "key-policy-managed-storage",
    Statement : [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [local.cmk_admin_value]
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "Allow Databricks to use KMS key for managed services in the control plane",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::414351767826:root"
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "aws:PrincipalTag/DatabricksAccountId" : ["${var.databricks_account_id}"]
          }
        }
      }
    ]
    }
  )
}

resource "aws_kms_alias" "managed_storage_key_alias" {
  name          = "alias/${var.prefix}-managed-storage-key-alias"
  target_key_id = aws_kms_key.managed_storage.key_id
}

// Managed Key Configuration
resource "databricks_mws_customer_managed_keys" "managed_storage" {
  provider         = databricks.mws
  account_id = var.databricks_account_id
  aws_key_info {
    key_arn   = aws_kms_key.managed_storage.arn
    key_alias = aws_kms_alias.managed_storage_key_alias.name
  }
  use_cases = ["MANAGED_SERVICES"]
}

// Workspace Storage Key Configuration
resource "databricks_mws_customer_managed_keys" "workspace_storage" {
  provider         = databricks.mws
  account_id = var.databricks_account_id
  aws_key_info {
    key_arn   = aws_kms_key.workspace_storage.arn
    key_alias = aws_kms_alias.workspace_storage_key_alias.name
  }
  use_cases = ["STORAGE"]
}

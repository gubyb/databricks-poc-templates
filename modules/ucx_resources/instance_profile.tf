resource "aws_s3_bucket" "instance_profile_bucket" {
  bucket        = "${var.prefix}-instance-profile-bucket"
  force_destroy = true
  tags          = var.tags
  tags_all      = var.tags
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.instance_profile_bucket.id
  policy = data.aws_iam_policy_document.instance_profile_bucket_access.json
}

data "aws_iam_policy_document" "instance_profile_bucket_access" {
  policy_id = "${var.prefix}-instance_profile_bucket_access"
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.role_for_s3_access.arn]
    }

    effect  = "Allow"

    actions = [
        "s3:GetBucketLocation",
        "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.instance_profile_bucket.arn,
    ]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.role_for_s3_access.arn]
    }

    effect  = "Allow"

    actions = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:GetObjectVersion",
        "s3:PutObjectAcl"
    ]

    resources = [
      "${aws_s3_bucket.instance_profile_bucket.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_public_access_block" "root_storage_bucket" {
  bucket             = aws_s3_bucket.instance_profile_bucket.id
  block_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls = true
  depends_on         = [aws_s3_bucket.instance_profile_bucket]
}

resource "aws_s3_bucket_versioning" "external_versioning" {
  bucket = aws_s3_bucket.instance_profile_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_iam_policy" "external_data_access" {
  // Terraform's "jsonencode" function converts a
  // Terraform expression's result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${aws_s3_bucket.instance_profile_bucket.id}-access"
    Statement = [
      {
        "Effect": "Allow",
        "Action": [
          "s3:ListBucket"
        ],
      "Resource": [
          "${aws_s3_bucket.instance_profile_bucket.arn}"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion",
          "s3:PutObjectAcl"
        ],
        "Resource": [
          "${aws_s3_bucket.instance_profile_bucket.arn}/*"
        ]
      }
    ]
  })
  tags = var.tags
  tags_all = var.tags
}

data "aws_iam_policy_document" "assume_role_for_ec2" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}
resource "aws_iam_role" "role_for_s3_access" {
  name               = "${var.prefix}-shared-ec2-role-for-s3"
  description        = "Role for shared access"
  assume_role_policy = data.aws_iam_policy_document.assume_role_for_ec2.json

  managed_policy_arns = [aws_iam_policy.external_data_access.arn]
  
  tags = var.tags
  tags_all = var.tags
}
data "aws_iam_policy_document" "pass_role_for_s3_access" {
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.role_for_s3_access.arn]
  }
}
resource "aws_iam_policy" "pass_role_for_s3_access" {
  name   = "${var.prefix}-shared-pass-role-for-s3-access"
  path   = "/"
  policy = data.aws_iam_policy_document.pass_role_for_s3_access.json

  tags = var.tags
  tags_all = var.tags
}
resource "aws_iam_role_policy_attachment" "cross_account" {
  policy_arn = aws_iam_policy.pass_role_for_s3_access.arn
  role       = var.crossaccount_role_name
}
resource "aws_iam_instance_profile" "shared" {
  name = "${var.prefix}-shared-instance-profile"
  role = aws_iam_role.role_for_s3_access.name

  tags = var.tags
  tags_all = var.tags
}

resource "time_sleep" "wait" {
  depends_on = [
    aws_iam_instance_profile.shared
  ]
  create_duration = "10s"
}

resource "databricks_instance_profile" "shared" {
  instance_profile_arn = aws_iam_instance_profile.shared.arn
  depends_on         = [time_sleep.wait]
}

data "databricks_spark_version" "latest" {}
data "databricks_node_type" "smallest" {
  local_disk = true
}
resource "databricks_cluster" "this" {
  cluster_name            = "instance_profile_single"
  data_security_mode      = "SINGLE_USER"
  single_user_name        = var.single_user_name
  spark_version           = data.databricks_spark_version.latest.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 10
  autoscale {
    min_workers = 1
    max_workers = 1
  }
  aws_attributes {
    instance_profile_arn   = databricks_instance_profile.shared.id
    availability           = "SPOT"
    first_on_demand        = 1
    spot_bid_price_percent = 100
  }
}


# UC Storage credential

resource "aws_iam_policy" "external_data_access_uc" {
  // Terraform's "jsonencode" function converts a
  // Terraform expression's result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${aws_s3_bucket.instance_profile_bucket.id}-access"
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
          aws_s3_bucket.instance_profile_bucket.arn,
          "${aws_s3_bucket.instance_profile_bucket.arn}/*"
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
  name                = "${var.prefix}-instance-profile-cred"
  assume_role_policy  = data.aws_iam_policy_document.passrole_for_uc.json
  managed_policy_arns = [aws_iam_policy.external_data_access_uc.arn]
  tags = var.tags
  tags_all = var.tags
}


resource "databricks_service_principal" "instance_profile_spn" {
  display_name = "${var.prefix}-instance-prof-spn"
}

resource "databricks_service_principal_role" "my_spn_instance_profile" {
  service_principal_id = databricks_service_principal.instance_profile_spn.id
  role     = databricks_instance_profile.shared.id
}

resource "databricks_secret_scope" "ehms_scope" {
  name = "ehms-scope"
}

resource "databricks_secret" "ehms_password" {
  key          = "ehms_password"
  string_value = var.rds_password
  scope        = databricks_secret_scope.ehms_scope.id
}

resource "databricks_notebook" "ehms_setup" {
  source = "${path.module}/notebooks/ehms_setup.py"
  path   = "/Workspace/Shared/ehms_setup.py"
}

resource "databricks_notebook" "test_table_create" {
  source = "${path.module}/notebooks/test_table_create.py"
  path   = "/Workspace/Shared/test_table_create.py"
}

resource "databricks_workspace_file" "hive_schema_sql" {
  source = "${path.module}/ehms_scripts/hive-schema-2.3.0.mysql.sql"
  path   = "/Workspace/Shared/hive-schema-2.3.0.mysql.sql"
}

resource "databricks_workspace_file" "hive_schema_txn_sql" {
  source = "${path.module}/ehms_scripts/hive-txn-schema-2.3.0.mysql.sql"
  path   = "/Workspace/Shared/hive-txn-schema-2.3.0.mysql.sql"
}

resource "databricks_job" "setup_ehms_tf" {
  task {
    task_key = "setup-ehms"
    run_if   = "ALL_SUCCESS"
    notebook_task {
      notebook_path = databricks_notebook.ehms_setup.id
      base_parameters = {
        database      = "${aws_db_instance.default.db_name}"
        endpoint_name = "${aws_vpc_endpoint.nlb_endpoint.dns_entry[0].dns_name}"
        user_name     = "${aws_db_instance.default.username}"
      }
    }
    job_cluster_key = "ehms-setup-cluster"
  }
  task {
    task_key = "test-ehms"
    run_if   = "ALL_SUCCESS"
    notebook_task {
      notebook_path = databricks_notebook.test_table_create.id
    }
    job_cluster_key = "test-table-create-ehms"
    depends_on {
      task_key = "setup-ehms"
    }
  }
  queue {
    enabled = true
  }
  name = "setup-ehms"
  job_cluster {
    new_cluster {
      spark_version = "14.3.x-scala2.12"
      spark_conf = {
        "spark.databricks.cluster.profile" = "singleNode"
        "spark.master"                     = "local[*, 4]"
      }
      runtime_engine      = "STANDARD"
      node_type_id        = "r6id.xlarge"
      enable_elastic_disk = true
      data_security_mode  = "SINGLE_USER"
      custom_tags = {
        ResourceClass = "SingleNode"
      }
      aws_attributes {
        zone_id                = "ap-southeast-1a"
        spot_bid_price_percent = 100
        first_on_demand        = 1
        availability           = "SPOT_WITH_FALLBACK"
      }
    }
    job_cluster_key = "ehms-setup-cluster"
  }
  job_cluster {
    new_cluster {
      spark_version = "14.3.x-scala2.12"
      spark_conf = {
        "datanucleus.schema.autoCreateTables"                = "true"
        "spark.databricks.cluster.profile"                   = "singleNode"
        "spark.hadoop.javax.jdo.option.ConnectionDriverName" = "org.mariadb.jdbc.Driver"
        "spark.hadoop.javax.jdo.option.ConnectionPassword"   = var.rds_password
        "spark.hadoop.javax.jdo.option.ConnectionURL"        = "jdbc:mysql://${aws_vpc_endpoint.nlb_endpoint.dns_entry[0].dns_name}:3306/${aws_db_instance.default.db_name}"
        "spark.hadoop.javax.jdo.option.ConnectionUserName"   = aws_db_instance.default.username
        "spark.master"                                       = "local[*, 4]"
        "spark.sql.catalogImplementation"                    = "hive"
        "spark.sql.hive.metastore.jars"                      = "builtin"
        "spark.sql.hive.metastore.version"                   = "2.3.9"
      }
      runtime_engine      = "STANDARD"
      node_type_id        = "r6id.xlarge"
      enable_elastic_disk = true
      data_security_mode  = "SINGLE_USER"
      custom_tags = {
        ResourceClass = "SingleNode"
      }
      aws_attributes {
        zone_id                = "ap-southeast-1a"
        spot_bid_price_percent = 100
        first_on_demand        = 1
        availability           = "SPOT_WITH_FALLBACK"
      }
    }
    job_cluster_key = "test-table-create-ehms"
  }
}

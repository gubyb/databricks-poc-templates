# Databricks notebook source
# Creating text widgets for user input on Databricks notebooks.
# These widgets allow users to input values for endpoint_name, user_name, and database which are used in subsequent cells.

# Widget for inputting the endpoint name. Default value is set to a placeholder AWS VPC endpoint.
dbutils.widgets.text("endpoint_name", "endpoint.aws-region.vpce.amazonaws.com")

# Widget for inputting the user name. Default value is set to 'admin'.
dbutils.widgets.text("user_name", "admin")

# Widget for inputting the database name. Default value is set to 'database'.
dbutils.widgets.text("database", "database")

# COMMAND ----------

import os

# Retrieving user inputs from widgets and setting them as environment variables.
# These inputs include the endpoint name, user name, and database name.
# Additionally, a secret (password) is fetched from a secure vault (Databricks secret scope) and also set as an environment variable.

# Fetching values from widgets created in a previous cell.
endpoint_name = dbutils.widgets.get("endpoint_name")
user_name = dbutils.widgets.get("user_name")
database = dbutils.widgets.get("database")

# Setting environment variables with the fetched values for use in subsequent operations.
os.environ['endpoint_name'] = endpoint_name
os.environ['user_name'] = user_name
os.environ['database'] = database

# Fetching a secret value (password) from a Databricks secret scope and setting it as an environment variable.
os.environ['password'] = dbutils.secrets.get(scope="ehms-scope", key="ehms_password")

# COMMAND ----------

# MAGIC %sh
# MAGIC # Navigate to the /tmp directory
# MAGIC mysql -h $endpoint_name -u $user_name -p$password -e "DROP DATABASE IF EXISTS $database;"
# MAGIC mysql -h $endpoint_name -u $user_name -p$password -e "CREATE DATABASE IF NOT EXISTS $database;"
# MAGIC
# MAGIC # Import the Hive schema from a SQL file into the newly created or existing database
# MAGIC mysql -h $endpoint_name -u $user_name -p$password -D $database < /Workspace/Shared/hive-schema-2.3.0.mysql.sql
# MAGIC mysql -h $endpoint_name -u $user_name -p$password -D $database -e "SHOW TABLES;"

# COMMAND ----------



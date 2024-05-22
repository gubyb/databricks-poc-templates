# Databricks notebook source
# MAGIC %sql
# MAGIC CREATE
# MAGIC OR REPLACE TEMPORARY VIEW raw_diamonds USING CSV OPTIONS (
# MAGIC   path "/databricks-datasets/Rdatasets/data-001/csv/ggplot2/diamonds.csv",
# MAGIC   header "true",
# MAGIC   inferSchema "true"
# MAGIC );
# MAGIC SELECT
# MAGIC   *
# MAGIC FROM
# MAGIC   raw_diamonds;

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE
# MAGIC OR REPLACE TABLE external_bronze_diamonds USING DELTA LOCATION 'dbfs:/user/hive/external_hms_test/external_bronze_diamonds' AS
# MAGIC SELECT
# MAGIC   *
# MAGIC FROM
# MAGIC   raw_diamonds;
# MAGIC SELECT
# MAGIC   *
# MAGIC From
# MAGIC   external_bronze_diamonds

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE
# MAGIC OR REPLACE TABLE external_silver_diamonds USING DELTA LOCATION 'dbfs:/user/hive/external_hms_test/external_silver_diamonds' AS
# MAGIC SELECT
# MAGIC   carat,
# MAGIC   cut,
# MAGIC   color,
# MAGIC   clarity,
# MAGIC   depth,
# MAGIC   price
# MAGIC FROM
# MAGIC   external_bronze_diamonds;
# MAGIC SELECT
# MAGIC   *
# MAGIC FROM
# MAGIC   external_silver_diamonds;

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE OR REPLACE TABLE external_gold_diamonds
# MAGIC USING DELTA LOCATION 'dbfs:/user/hive/external_hms_test/external_gold_diamonds'
# MAGIC AS SELECT
# MAGIC     carat,
# MAGIC     cut,
# MAGIC     color,
# MAGIC     clarity,
# MAGIC     price,
# MAGIC     CASE
# MAGIC         WHEN price >= 2000 THEN 'High'
# MAGIC         WHEN price >= 1000 THEN 'Medium'
# MAGIC         ELSE 'Low'
# MAGIC     END AS price_category
# MAGIC FROM external_silver_diamonds;
# MAGIC SELECT * FROM external_gold_diamonds

# COMMAND ----------


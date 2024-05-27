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
# MAGIC OR REPLACE TABLE bronze_diamonds USING DELTA AS
# MAGIC SELECT
# MAGIC   *
# MAGIC FROM
# MAGIC   raw_diamonds;
# MAGIC SELECT
# MAGIC   *
# MAGIC From
# MAGIC   bronze_diamonds

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE
# MAGIC OR REPLACE TABLE silver_diamonds USING DELTA AS
# MAGIC SELECT
# MAGIC   carat,
# MAGIC   cut,
# MAGIC   color,
# MAGIC   clarity,
# MAGIC   depth,
# MAGIC   price
# MAGIC FROM
# MAGIC   bronze_diamonds;
# MAGIC SELECT
# MAGIC   *
# MAGIC FROM
# MAGIC   silver_diamonds;

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE OR REPLACE TABLE gold_diamonds
# MAGIC USING DELTA
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
# MAGIC FROM silver_diamonds;
# MAGIC SELECT * FROM gold_diamonds
# Databricks notebook source
# MAGIC %sql
# MAGIC DROP TABLE IF EXISTS diamonds;
# MAGIC
# MAGIC CREATE TABLE diamonds (
# MAGIC   carat DOUBLE,
# MAGIC   cut STRING,
# MAGIC   color STRING,
# MAGIC   clarity STRING,
# MAGIC   depth DOUBLE,
# MAGIC   table DOUBLE,
# MAGIC   price INT,
# MAGIC   x DOUBLE,
# MAGIC   y DOUBLE,
# MAGIC   z DOUBLE
# MAGIC )
# MAGIC USING CSV
# MAGIC OPTIONS (
# MAGIC   path "/databricks-datasets/Rdatasets/data-001/csv/ggplot2/diamonds.csv",
# MAGIC   header "true"
# MAGIC );
# MAGIC
# MAGIC SELECT * FROM diamonds;

# COMMAND ----------



# Databricks notebook source

dbutils.widgets.text("bucket", "", label = "Bucket name")
bucket_name = dbutils.widgets.get("bucket")
print(f"USING BUCKET: {bucket_name}")

# COMMAND ----------

# Databricks notebook source
from pyspark.sql.functions import rand, date_add, col, when

# Generate random data
num_rows = 1000
df = spark.range(num_rows).select(rand().alias("random_data"))

# Add additional features
df = df.withColumn("date", date_add("current_date", (col("random_data") * 365).cast("int")))
df = df.withColumn("average_temperature", when(col("random_data") > 0.5, 25).otherwise(15))
df = df.withColumn("rainfall", when(col("random_data") > 0.5, 50).otherwise(10))
df = df.withColumn("weekend_flag", when(col("random_data") > 0.5, True).otherwise(False))

# Write DataFrame as Delta table
df.write.format("delta").save("s3a://${bucket_name}/tables/my_instance_profile_table")

# COMMAND ----------

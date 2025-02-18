# Databricks notebook source
from pyspark.sql.functions import col, when
import random

# Generate some random data
data = spark.range(1000).toDF("id").withColumn("value", (col("id") * 10) + random.randint(1, 100))

# Perform some transformations
transformed_data = data.withColumn("category", when(col("value") > 500, "high").otherwise("low"))

# Process the data to extract insights
high_count = transformed_data.filter(col("category") == "high").count()
low_count = transformed_data.filter(col("category") == "low").count()

print(f"High category count: {high_count}")
print(f"Low category count: {low_count}")

# Optionally, you can also visualize the data or perform more complex analysis
# For example, using Databricks' built-in plotting libraries:
# display(transformed_data.groupBy("category").count())

# COMMAND ----------

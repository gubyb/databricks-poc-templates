# Databricks notebook source
dbutils.widgets.text("bucket", "", label = "Bucket name")
bucket_name = dbutils.widgets.get("bucket")
print(f"USING BUCKET: {bucket_name}")

# COMMAND ----------

import botocore.session

# Create a botocore session
session = botocore.session.Session()
# Create an S3 client
client = session.create_client('s3', region_name='ap-southeast-1')
# List folders in the bucket
response = client.list_objects_v2(Bucket=bucket_name, Delimiter='/')
# Extract folder names from the response
folders = [prefix['Prefix'] for prefix in response.get('CommonPrefixes', [])]
# Print the folder names
for folder in folders:
    print(folder)

# COMMAND ----------



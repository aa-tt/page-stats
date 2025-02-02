from pyspark.sql import SparkSession
from pyspark.sql.functions import col, sum as _sum, weekofyear, year, lit
import influxdb_client
from datetime import datetime, timedelta

# Initialize Spark session with extra classpath for JDBC driver
spark = SparkSession.builder \
    .appName("ConsolidatorService") \
    .config("spark.driver.extraClassPath", "/opt/spark/jars/postgresql-42.2.23.jar") \
    .config("spark.executor.extraClassPath", "/opt/spark/jars/postgresql-42.2.23.jar") \
    .getOrCreate()

# InfluxDB configuration
influxdb_url = "http://influxdb.zenoptics.svc.cluster.local:8086"
influxdb_token = "your-influxdb-token"
influxdb_org = "your-org"
influxdb_bucket = "page_view_bucket"

# PostgreSQL configuration
pg_url = "jdbc:postgresql://postgres.zenoptics.svc.cluster.local:5432/zenopticsdb"
pg_properties = {
    "user": "your-username",
    "password": "your-password",
    "driver": "org.postgresql.Driver"
}

# Read data from InfluxDB
query = f'from(bucket: "{influxdb_bucket}") |> range(start: -1w)'
influx_client = influxdb_client.InfluxDBClient(url=influxdb_url, token=influxdb_token, org=influxdb_org)
tables = influx_client.query_api().query(query, org=influxdb_org)

# Convert InfluxDB data to Spark DataFrame
data = []
for table in tables:
    for record in table.records:
        data.append((record["pageName"], record["region"], record["_time"], record["_value"]))

# Check if data is empty
if not data:
    print("No data retrieved from InfluxDB.")
else:
    df = spark.createDataFrame(data, ["pageName", "region", "timestamp", "visits"])

    # Print the initial DataFrame
    print("Initial DataFrame:")
    df.show()

    # Process data: aggregate visits by pageName, region, and week
    df = df.withColumn("week", weekofyear(col("timestamp"))) \
           .withColumn("year", year(col("timestamp")))

    # Print the DataFrame after adding week and year columns
    print("DataFrame with week and year columns:")
    df.show()

    aggregated_df = df.groupBy("pageName", "region", "year", "week") \
                      .agg(_sum("visits").alias("visits"))

    # Print the aggregated DataFrame
    print("Aggregated DataFrame:")
    aggregated_df.show()

    # Add week's end timestamp
    aggregated_df = aggregated_df.withColumn("timestamp", lit(datetime.now() - timedelta(days=datetime.now().weekday() + 1)))

    # Select the required columns for PostgreSQL schema
    final_df = aggregated_df.select("pageName", "region", "timestamp", "visits")

    # Print the final DataFrame before writing to PostgreSQL
    print("Final DataFrame with timestamp:")
    final_df.show()

    # Write results to PostgreSQL
    final_df.write.jdbc(url=pg_url, table="region_weekly", mode="append", properties=pg_properties)

# Close InfluxDB client
influx_client.close()

# Stop Spark session
spark.stop()
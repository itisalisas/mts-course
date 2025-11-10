from onetl.connection import Hive, SparkHDFS
from onetl.db import DBWriter
from onetl.file import FileDFReader
from onetl.file.format import Parquet
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, year, dayofweek, when, round

spark = (
    SparkSession.builder.master("yarn")
    .appName("test_11_10")
    .config("spark.sql.warehouse.dir", "/user/hive/warehouse")
    .config("spark.hive.metastore.uris", "thrift://team-9-nn:9083")
    .enableHiveSupport()
    .getOrCreate()
)

hdfs = SparkHDFS(host="team-9-nn", port=9000, spark=spark, cluster="x")
hdfs.check()

reader = FileDFReader(connection=hdfs, format=Parquet(), source_path="/input")

df = reader.run(["dataset.parquet"])

print(df.count())

df.printSchema()

df_transformed = df

df_transformed = df_transformed.withColumn("YEAR", year(col("FL_DATE")))

df_transformed = df_transformed.withColumn(
    "DEP_DELAY_CATEGORY",
    when(col("DEP_DELAY") <= 0, "On Time")
    .when((col("DEP_DELAY") > 0) & (col("DEP_DELAY") <= 15), "Minor Delay")
    .when((col("DEP_DELAY") > 15) & (col("DEP_DELAY") <= 60), "Moderate Delay")
    .otherwise("Major Delay")
)

df_transformed = df_transformed.withColumn(
    "IS_LONG_DISTANCE",
    when(col("DISTANCE") > 1000, True).otherwise(False)
)

df_transformed = df_transformed.withColumn(
    "AVG_SPEED",
    round(col("DISTANCE") / (col("AIR_TIME") / 60), 2)
)

df_transformed = df_transformed.withColumn(
    "IS_WEEKEND",
    when((dayofweek(col("FL_DATE")) == 1) | (dayofweek(col("FL_DATE")) == 7), True)
    .otherwise(False)
)

df_transformed.printSchema()
df_transformed.show(10)

hive = Hive(spark=spark, cluster="x")
hive.check()

writer = DBWriter(connection=hive, target="test.flights", options=Hive.WriteOptions(partitionBy=["IS_LONG_DISTANCE"]))
writer.run(df_transformed)

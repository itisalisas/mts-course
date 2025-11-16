from prefect import flow, task
from prefect.cache_policies import NO_CACHE
from onetl.connection import Hive, SparkHDFS
from pyspark.sql import SparkSession
from onetl.db import DBWriter
from onetl.file import FileDFReader
from onetl.file.format import Parquet
from pyspark.sql.functions import col, year, dayofweek, when, round


@task(cache_policy=NO_CACHE)
def init_spark():
    spark = (
        SparkSession.builder.master("yarn")
        .appName("test_11_16")
        .config("spark.sql.warehouse.dir", "/user/hive/warehouse")
        .config("spark.hive.metastore.uris", "thrift://team-9-nn:9083")
        .enableHiveSupport()
        .getOrCreate()
    )
    return spark


@task(cache_policy=NO_CACHE)
def stop_spark(spark):
    spark.stop()


@task(cache_policy=NO_CACHE)
def extract(spark):
    hdfs = SparkHDFS(host="team-9-nn", port=9000, spark=spark, cluster="x").check()
    reader = FileDFReader(connection=hdfs, format=Parquet(), source_path="/input")
    df = reader.run(["dataset.parquet"])
    return df


@task(cache_policy=NO_CACHE)
def transform(df):
    df = df.withColumn("YEAR", year(col("FL_DATE")))

    df = df.withColumn(
        "DEP_DELAY_CATEGORY",
        when(col("DEP_DELAY") <= 0, "On Time")
        .when((col("DEP_DELAY") > 0) & (col("DEP_DELAY") <= 15), "Minor Delay")
        .when((col("DEP_DELAY") > 15) & (col("DEP_DELAY") <= 60), "Moderate Delay")
        .otherwise("Major Delay")
    )

    df = df.withColumn(
        "IS_LONG_DISTANCE",
        when(col("DISTANCE") > 1000, True).otherwise(False)
    )

    df = df.withColumn(
        "AVG_SPEED",
        round(col("DISTANCE") / (col("AIR_TIME") / 60), 2)
    )

    df = df.withColumn(
        "IS_WEEKEND",
        when((dayofweek(col("FL_DATE")) == 1) | (dayofweek(col("FL_DATE")) == 7), True)
        .otherwise(False)
    )
    return df


@task(cache_policy=NO_CACHE)
def load(df, spark):
    hive = Hive(spark=spark, cluster="x").check()

    writer = DBWriter(connection=hive, target="test.flights_prefect_flow", options=Hive.WriteOptions(partitionBy=["IS_LONG_DISTANCE"]))
    writer.run(df)


@flow
def process_data():
    spark = init_spark()

    df = extract(spark=spark)
    df = transform(df)
    load(df=df, spark=spark)
    stop_spark(spark=spark)

if __name__ == "__main__":
    process_data()

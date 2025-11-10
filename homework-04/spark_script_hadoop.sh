#!/bin/bash

set -xe

WORKING_DIR=/tmp/spark

hdfs dfs -put -f /tmp/dataset.parquet /input

python3 -m venv .venv
source .venv/bin/activate

pip install -U pip
pip install "pyspark==3.5.6"
pip install "onetl[spark,files]"

cp $WORKING_DIR/configs/profile.sh ~/.profile
. ~/.profile

python $WORKING_DIR/python/spark.py

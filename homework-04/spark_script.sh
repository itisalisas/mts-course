#!/bin/bash

set -xe

HADOOP_USER="hadoop"
WORKING_DIR=/tmp/spark

if [ ! -f /tmp/dataset.parquet ]; then
    wget 'https://drive.google.com/uc?export=download&id=1JitVqB12Ize0DcgXY2UMEgc5PYDcWT9U' -O /tmp/dataset.parquet
fi

cat $WORKING_DIR/passwords/team | sudo -S apt install -y python3-venv
cat $WORKING_DIR/passwords/hadoop | sudo -S -i -u ${HADOOP_USER} /tmp/spark/spark_script_hadoop.sh

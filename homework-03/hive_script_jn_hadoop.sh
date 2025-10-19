#!/bin/bash

set -xe

if [ ! -f data.csv ]; then
    wget --no-check-certificate https://rospatent.gov.ru/opendata/7730176088-tz/data-20241101-structure-20180828.csv
    mv data-20241101-structure-20180828.csv data.csv
fi

source .profile
hdfs dfs -mkdir -p /input
hdfs dfs -chmod g+w /input
hdfs dfs -put -f data.csv /input


headers="$(head -1 data.csv | LC_ALL=C tr -dc '\0-\177')"
headers=$(echo $headers | sed 's/ /_/g')
echo $headers | sed 's/,/ VARCHAR(1000), /g' > columns
cat > query.hql << 'EOF'
CREATE DATABASE IF NOT EXISTS test;
CREATE TABLE IF NOT EXISTS test.some_data (
EOF
cat columns >> query.hql
echo " VARCHAR(1000)) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';" >> query.hql
echo "LOAD DATA INPATH '/input/data.csv' INTO TABLE test.some_data;" >> query.hql

beeline -u jdbc:hive2://team-9-nn:5433 -f query.hql

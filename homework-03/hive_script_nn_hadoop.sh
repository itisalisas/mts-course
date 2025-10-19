#!/bin/bash

set -xe

if [ ! -d "apache-hive-4.0.0-alpha-2-bin" ]; then
    wget https://archive.apache.org/dist/hive/hive-4.0.0-alpha-2/apache-hive-4.0.0-alpha-2-bin.tar.gz
    tar -xzvf apache-hive-4.0.0-alpha-2-bin.tar.gz
fi

cd apache-hive-4.0.0-alpha-2-bin/lib
if [ ! -f "../bin/postgresql-42.7.4.jar" ]; then
    wget https://jdbc.postgresql.org/download/postgresql-42.7.4.jar
    cp postgresql-42.7.4.jar ../bin
fi

cd ../..
cp /tmp/hive/configs/hive-site.xml apache-hive-4.0.0-alpha-2-bin/conf
cp /tmp/hive/configs/profile.sh .profile
source .profile

hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -chmod g+w /user/hive/warehouse
hdfs dfs -mkdir -p /tmp
hdfs dfs -chmod g+w /tmp

if ! schematool -dbType postgres -info; then
    schematool -dbType postgres -initSchema
fi

hive --service metastore &
hive --hiveconf hive.server2.enable.doAs=false --hiveconf hive.security.authorization.enabled=false --service hiveserver2 1>> /tmp/hs2.log 2>> /tmp/hs2_e.log &

scp -o StrictHostKeyChecking=no -r apache-hive-4.0.0-alpha-2-bin/ hadoop@team-9-jn:/home/hadoop/

scp -r hadoop-3.4.0 hadoop@team-9-jn:/home/hadoop/

scp .profile hadoop@team-9-jn:/home/hadoop/

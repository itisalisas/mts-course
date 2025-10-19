#!/bin/bash

set -xe

HADOOP_USER="hadoop"

cat /tmp/hive/passwords/team | sudo -S apt install -y postgresql-client-16
cat /tmp/hive/passwords/hadoop | sudo -S -i -u ${HADOOP_USER} /tmp/hive/hive_script_nn_hadoop.sh

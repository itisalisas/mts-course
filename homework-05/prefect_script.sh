#!/bin/bash

set -xe

HADOOP_USER="hadoop"
WORKING_DIR=/tmp/prefect

cat $WORKING_DIR/passwords/team | sudo -S -i -u ${HADOOP_USER} $WORKING_DIR/prefect_script_hadoop.sh

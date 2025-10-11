#!/bin/bash

set -xe

HADOOP_USER="hadoop"

cat /tmp/yarn/passwords/team | sudo -S -i -u ${HADOOP_USER} /tmp/yarn/yarn_script_helper.sh

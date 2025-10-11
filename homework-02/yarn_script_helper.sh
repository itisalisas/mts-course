#!/bin/bash

set -xe

CLUSTER_NODES=("team-9-nn" "team-9-dn-00" "team-9-dn-01")
HADOOP_USER="hadoop"
HADOOP_VERSION="3.4.0"
HADOOP_HOME="/home/${HADOOP_USER}/hadoop-${HADOOP_VERSION}"

for node in "${CLUSTER_NODES[@]}"; do
    scp /tmp/yarn/configs/yarn-site.xml ${HADOOP_USER}@$node:${HADOOP_HOME}/etc/hadoop/yarn-site.xml
    scp /tmp/yarn/configs/mapred-site.xml ${HADOOP_USER}@$node:${HADOOP_HOME}/etc/hadoop/mapred-site.xml
done

ssh ${HADOOP_USER}@team-9-nn "${HADOOP_HOME}/sbin/start-yarn.sh"
ssh ${HADOOP_USER}@team-9-nn "source ~/.profile && mapred --daemon start historyserver"

for node in "${CLUSTER_NODES[@]}"; do
    ssh ${HADOOP_USER}@${node} jps
done

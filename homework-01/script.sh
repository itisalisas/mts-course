#!/bin/bash

set -xe

declare -A HOSTS
HOSTS=(
    ["team-9-jn"]="192.168.1.38"
    ["team-9-nn"]="192.168.1.39"
    ["team-9-dn-00"]="192.168.1.40"
    ["team-9-dn-01"]="192.168.1.41"
)

TEAM_USER="team"
HADOOP_USER="hadoop"
HADOOP_USER_PASSWORD="Hadoop140146659++"
HADOOP_VERSION="3.4.0"
HADOOP_URL="https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"
HADOOP_ARCHIVE=$(basename "$HADOOP_URL")
HADOOP_HOME="/home/${HADOOP_USER}/hadoop-${HADOOP_VERSION}"
CLUSTER_NODES=("team-9-nn" "team-9-dn-00" "team-9-dn-01")

cp -R configs /tmp/hadoop_configs

if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -N ""
fi

for host_name in "${!HOSTS[@]}"; do
    host_ip=${HOSTS[$host_name]}
    ssh-copy-id -i ~/.ssh/id_ed25519.pub ${TEAM_USER}@${host_ip}
done

HOSTS_CONFIG=""
for host_name in "${!HOSTS[@]}"; do
    HOSTS_CONFIG+="${HOSTS[$host_name]} ${host_name}\n"
done

for host_name in "${!HOSTS[@]}"; do
    host_ip=${HOSTS[$host_name]}
    ssh ${TEAM_USER}@${host_ip} "
        set -e
        if id -u ${HADOOP_USER} &>/dev/null; then
            echo 'User ${HADOOP_USER} already exists.'
        else
            sudo useradd -m -s /bin/bash ${HADOOP_USER}
            echo '${HADOOP_USER}:${HADOOP_USER_PASSWORD}' | sudo chpasswd
        fi
        echo -e '${HOSTS_CONFIG}' | sudo tee /etc/hosts
    "
done

sudo -i -u ${HADOOP_USER} bash << 'EOF_HADOOP_SCRIPT'
    set -xe

    declare -A HOSTS
    HOSTS=(
        ["team-9-jn"]="192.168.1.38"
        ["team-9-nn"]="192.168.1.39"
        ["team-9-dn-00"]="192.168.1.40"
        ["team-9-dn-01"]="192.168.1.41"
    )

    HADOOP_USER="hadoop"
    HADOOP_USER_PASSWORD="Hadoop140146659++"
    HADOOP_VERSION="3.4.0"
    HADOOP_URL="https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"
    HADOOP_ARCHIVE=$(basename "$HADOOP_URL")
    HADOOP_HOME="/home/${HADOOP_USER}/hadoop-${HADOOP_VERSION}"
    CLUSTER_NODES=("team-9-nn" "team-9-dn-00" "team-9-dn-01")

    if [ ! -f ~/.ssh/id_ed25519 ]; then
        ssh-keygen -t ed25519 -N ""
    fi

    for host_name in "${!HOSTS[@]}"; do
        host_ip=${HOSTS[$host_name]}
        ssh-copy-id -i ~/.ssh/id_ed25519.pub ${HADOOP_USER}@${host_ip}
    done

    if [ ! -f ${HADOOP_ARCHIVE} ]; then
        wget ${HADOOP_URL}
    fi

    for node in "${CLUSTER_NODES[@]}"; do
        scp ${HADOOP_ARCHIVE} ${node}:/home/${HADOOP_USER}
        ssh ${HADOOP_USER}@${node} "tar -xzf ${HADOOP_ARCHIVE}"
    done

    for node in "${CLUSTER_NODES[@]}"; do
        scp /tmp/hadoop_configs/profile.sh ${HADOOP_USER}@${node}:~/.profile
        scp /tmp/hadoop_configs/workers ${HADOOP_USER}@${node}:${HADOOP_HOME}/etc/hadoop/workers
        scp /tmp/hadoop_configs/core-site.xml ${HADOOP_USER}@${node}:${HADOOP_HOME}/etc/hadoop/core-site.xml
        scp /tmp/hadoop_configs/hdfs-site.xml ${HADOOP_USER}@${node}:${HADOOP_HOME}/etc/hadoop/hdfs-site.xml
        ssh ${HADOOP_USER}@${node} "hadoop version"
        ssh ${HADOOP_USER}@${node} "echo \"JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))\" >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh"
    done

    ssh ${HADOOP_USER}@team-9-nn "${HADOOP_HOME}/bin/hdfs namenode -format"
    ssh ${HADOOP_USER}@team-9-nn "${HADOOP_HOME}/sbin/start-dfs.sh"
    for node in "${CLUSTER_NODES[@]}"; do
        ssh ${HADOOP_USER}@${node} jps
    done

EOF_HADOOP_SCRIPT

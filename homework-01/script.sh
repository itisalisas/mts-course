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

mkdir -p /tmp/hadoop_configs
cp -R configs/* /tmp/hadoop_configs/

if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
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
    ssh -t ${TEAM_USER}@${host_ip} "
        set -xe
        if id -u ${HADOOP_USER} &>/dev/null; then
            echo 'User ${HADOOP_USER} already exists.'
        else
            sudo useradd -m -s /bin/bash ${HADOOP_USER}
            echo '${HADOOP_USER}:${HADOOP_USER_PASSWORD}' | sudo chpasswd
        fi
        echo -e '${HOSTS_CONFIG}' | sudo tee /etc/hosts
    "
done

ssh -t ${HADOOP_USER}@team-9-jn "
    set -xe
    if [ ! -f /home/${HADOOP_USER}/.ssh/id_ed25519 ]; then
        ssh-keygen -t ed25519 -N '' -f /home/${HADOOP_USER}/.ssh/id_ed25519
    fi

    ssh-copy-id -i /home/${HADOOP_USER}/.ssh/id_ed25519.pub ${HADOOP_USER}@team-9-nn
    ssh-copy-id -i /home/${HADOOP_USER}/.ssh/id_ed25519.pub ${HADOOP_USER}@team-9-dn-00
    ssh-copy-id -i /home/${HADOOP_USER}/.ssh/id_ed25519.pub ${HADOOP_USER}@team-9-dn-01
"

cp script_hadoop.sh /tmp/

sudo -i -u ${HADOOP_USER} /tmp/script_hadoop.sh

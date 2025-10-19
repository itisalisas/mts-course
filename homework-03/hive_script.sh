#!/bin/bash

set -xe

TEAM_USER="team"

cd /tmp/hive
scp -o StrictHostKeyChecking=no -r . ${TEAM_USER}@team-9-dn-01:/tmp/hive
scp -o StrictHostKeyChecking=no -r . ${TEAM_USER}@team-9-nn:/tmp/hive

ssh ${TEAM_USER}@team-9-dn-01 "/tmp/hive/hive_script_dn_01.sh"
ssh ${TEAM_USER}@team-9-nn "/tmp/hive/hive_script_nn.sh"
cat /tmp/hive/passwords/team | sudo -S -i -u hadoop /tmp/hive/hive_script_jn_hadoop.sh

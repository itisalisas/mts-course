#!/bin/bash

set -xe

cat /tmp/hive/passwords/team | sudo -S apt install -y postgresql-16
cat /tmp/hive/passwords/team | sudo -S systemctl start postgresql

cat /tmp/hive/passwords/team | sudo -S -i -u postgres psql -f /tmp/hive/sql/init.sql

cat /tmp/hive/passwords/team | sudo -S cp /tmp/hive/configs/postgresql.conf /etc/postgresql/16/main/postgresql.conf
cat /tmp/hive/passwords/team | sudo -S cp /tmp/hive/configs/pg_hba.conf /etc/postgresql/16/main/pg_hba.conf

cat /tmp/hive/passwords/team | sudo -S systemctl restart postgresql

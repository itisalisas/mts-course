create database metastore;
create user hive with password 'hive';
grant all privileges on database "metastore" to hive;
alter database metastore owner to hive;

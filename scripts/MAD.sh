#!/bin/bash

# Mongo DB
yum install mongodb-server -y
mkdir -p /data/db
/usr/bin/mongos &

# Apache Spark
yum install java-1.8.0-openjdk -y
cd /opt
wget http://mirrors.ukfast.co.uk/sites/ftp.apache.org/spark/spark-2.4.4/spark-2.4.4-bin-hadoop2.7.tgz
tar -xzf spark-2.4.4-bin-hadoop2.7.tgz
ln -s /opt/spark-2.4.4-bin-hadoop2.7 /opt/spark
/opt/spark/sbin/start-master.sh

# Django
yum install python2-django -y

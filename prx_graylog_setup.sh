#!/bin/sh
#
#
#
echo Installing OpenJDK Java 1.8.0
yum install -y java-1.8.0-openjdk-headless.x86_64
#
#
#
echo Downloading MongoDB repo file
wget -P /etc/yum.repos.d "https://raw.githubusercontent.com/telciontms/zbx-prx/master/mongodb-org-4.4.repo"
#
#
#
echo Installing latest version of MongoDB:
yum update
yum install -y mongodb-org
systemctl daemon-reload
systemctl enable mongod.service
systemctl start mongod.service
systemctl --type=service --state=active | grep mongod
#
#
#
echo Installing Elasticsearch
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

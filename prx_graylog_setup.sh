#!/bin/sh
#
#
#
echo Updating CentOS before installation...
yum -y update
yum -y upgrade
#
#
#
echo Installing OpenJDK Java 1.8.0
yum install -y java-1.8.0-openjdk-headless.x86_64
#
#
#
echo Downloading MongoDB repo file
wget -P /etc/yum.repos.d "https://raw.githubusercontent.com/telciontms/zbx-prx/master/mongodb-org-4.4.repo" --no-check-certificate
#
#
#
echo Installing latest version of MongoDB:
yum -y update
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
wget -P /etc/yum.repos.d "https://raw.githubusercontent.com/telciontms/zbx-prx/master/elasticsearch.repo" --no-check-certificate
yum -y update
yum install -y elasticsearch-oss
sleep 10
#
#
#
echo Configuring elasticsearch
sed -i 's/#cluster.name: my-application/cluster.name: graylog/g' /etc/elasticsearch/elasticsearch.yml
sed -i -e "\$aaction.auto_create_index: false" /etc/elasticsearch/elasticsearch.yml
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl restart elasticsearch.service
systemctl --type=service --state=active | grep elasticsearch
#
#
#
echo Installing Graylog
rpm -Uvh https://packages.graylog2.org/repo/packages/graylog-3.2-repository_latest.rpm
yum -y update
yum -y install graylog-server
#
#
#
echo Configuring Graylog
echo You must set a Graylog password_secret
sleep 3
echo This password_secret MUST BE 16 characters in length.
sleep 3
read -p "Press [Enter] to acknowledge the 16 character minimum..." NULL
read -p "Press [Enter] to when you are ready to type the password..." NULL
stty -echo
printf "Specify Graylog password_secret now: "
read SECRETPASSWORD
stty echo
echo " "
stty -echo
printf "Specify Graylog Web Login: "
read WEBLOGIN
stty echo
echo " "
echo " "
WEBLOGIN256=$(echo -n "$WEBLOGIN" | sha256sum | cut -d" " -f1)
sed -i "s/password_secret =/password_secret = $SECRETPASSWORD/g" /etc/graylog/server/server.conf
sed -i "s/root_password_sha2 =/root_password_sha2 = $WEBLOGIN256/g" /etc/graylog/server/server.conf
IPADDRESS=$(hostname -I)
sed -i "s/#http_bind_address = 127.0.0.1:9000/http_bind_address = $IPADDRESS:9000/g" /etc/graylog/server/server.conf
sed -i "s/#http_bind_address = $IPADDRESS :9000/http_bind_address = $IPADDRESS:9000/g" /etc/graylog/server/server.conf
#
#
#
echo Configuring Firewall Port Forwarding for UDP 514
firewall-cmd --zone=work --permanent --add-port=9000/tcp
firewall-cmd --zone=work --permanent --add-forward-port=port=514:proto=udp:toport=1514
firewall-cmd --reload
echo When configuring Graylog Syslog you must use UDP port 1514
#
#
#
echo Starting Graylog
systemctl daemon-reload
systemctl enable graylog-server
systemctl start graylog-server
#
#
#
echo "A reboot is required to complete the setup process."
read -p "Press [Enter] to reboot the system..." NULL
echo "The system will be rebooting in 10 seconds..."
sleep 10
reboot

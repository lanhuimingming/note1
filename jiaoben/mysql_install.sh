#!/bin/bash

yum -y install mariadb-server mariadb
systemctl start mariadb
systemctl enable mariadb
mysqladmin -u root password 'redhat'

mysql -predhat <<EOT
drop database test;
delete from mysql.user where user='';
create database zabbix charset utf8;
grant all on zabbix.* to zabbix@'%' identified by 'uplooking';
flush privileges;
EOT




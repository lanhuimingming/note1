#!/bin/bash
#关闭SELINUX和防火墙
sed -i "s/^SELINUX=.*/SELINUX=disabled/" /etc/selinux/config
setenforce 0
iptables -F
#获取RPM包
wget 172.25.254.250:/notes/project/UP200/UP200_cacti-master/pkg/*

#expect <<EOF
#spwan lftp 172.25.254.250:/notes/project/UP200/UP200_cacti-master
#expect ">"
#send "mirror pkg/\r"
#expect ">"
#send "exit"
#expect eof
#EOF

#安装RPM包
yum -y install httpd php php-mysql mariadb-server mariadb
yum -y localinstall cacti-0.8.8b-7.el7.noarch.rpm php-snmp-5.4.16-23.el7_0.3.x86_64.rpm 

#设置数据库
systemctl start mariadb
mysql  -e "create database cacti;"
mysql  -e "grant all on cacti.* to cactidb@'localhost' identified by '123456';"
mysql  -e "flush privileges;"

#mysql <<EOF
#create database cacti;
#grant all on cacti.* to cactidb@'localhost' identified by '123456';
#exit
#EOF

#导入数据
mysql -ucactidb -p123456 cacti < /usr/share/doc/cacti-0.8.8b/cacti.sql

#修改连接数据库的配置文件/etc/cacti/db.php
sed -i "s/^\$database_username.*/\$database_username = \"cactidb\"\;/" /etc/cacti/db.php
sed -i "s/^\$database_password.*/\$database_password = \"123456\"\;/" /etc/cacti/db.php


 
#修改配置文件让主机允许登陆
sed -i "s/\t\tRequire host localhost/\t\tRequire all granted/" /etc/httpd/conf.d/cacti.conf

#设置时区并同步修改时区
timedatectl set-timezone Asia/Shanghai

sed -i 's/\;date.timezone =/\;date.timezone = Asia\/Shanghai/' /etc/php.ini

#修改同步计划
cat >/etc/cron.d/cacti<<END
*/5 * * * *     cacti   /usr/bin/php /usr/share/cacti/poller.php > /dev/null 2>&1
END

#启动服务
systemctl restart snmpd
systemctl restart httpd  && echo "cacti is success!"








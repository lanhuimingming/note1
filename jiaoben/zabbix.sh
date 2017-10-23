#!/bin/bash
#设置时区并同步时间
timedatectl set-timezone Asia/Shanghai 
ntpdate -u 172.25.254.254
setenforce 0
sed -i "s/SELINUX=.*/SELINUX=disabled/" /etc/selinux/config

#获取zabbix软件,并安装和解压包
lftp 172.25.254.250:/notes/project/software/zabbix <<EOT
mirror zabbix3.2/
exit
EOT

cd zabbix3.2
tar xf zabbix-3.2.7.tar.gz -C /usr/local/src/
yum install gcc gcc-c++ mariadb-devel libxml2-devel net-snmp-devel libcurl-devel -y

cd /usr/local/src/zabbix-3.2.7/
./configure --prefix=/usr/local/zabbix --enable-server --with-mysql --with-net-snmp --with-libcurl --with-libxml2 --enable-agent --enable-ipv6
make  && [ $? -eq 0 ] && make install 

#创建用户并修改配置文件
useradd zabbix

sed -i "s/^DBHost=.*/DBHost=172.25.9.13/" /usr/local/zabbix/etc/zabbix_server.conf
sed -i "s/^DBName=.*/DBName=zabbix/" /usr/local/zabbix/etc/zabbix_server.conf
sed -i "s/^DBUser=.*/DBUser=zabbix/" /usr/local/zabbix/etc/zabbix_server.conf
sed -i "s/^\#DBPassword=.*/DBPassword=uplooking/" /usr/local/zabbix/etc/zabbix_server.conf

#同步数据到mysql端
cd /usr/local/src/zabbix-3.2.7/database/mysql/
mysql -u zabbix -h 172.25.9.13 zabbix -puplooking < schema.sql 
mysql -u zabbix -h 172.25.9.13 zabbix -puplooking < images.sql 
mysql -u zabbix -h 172.25.9.13 zabbix -puplooking < data.sql 


cd /usr/local/zabbix/sbin/
./zabbix_server 
netstat -tnlp |grep zabbix && [ $? -eq 0 ] && echo "zabbix配置成功"














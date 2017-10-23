#!/bin/bash
#获取web软件包
lftp 172.25.254.250:/notes/project/software/zabbix <<EOT
mirror zabbix3.2/
exit
EOT

#安装包
cd zabbix3.2
yum -y install httpd php php-mysql
yum -y localinstall php-mbstring-5.4.16-23.el7_0.3.x86_64.rpm php-bcmath-5.4.16-23.el7_0.3.x86_64.rpm
yum localinstall zabbix-web-3.2.7-1.el7.noarch.rpm zabbix-web-mysql-3.2.7-1.el7.noarch.rpm

sed -i "s/#php_value date.timezone.*/php_value date.timezone Asia/Shanghai/" /etc/httpd/conf.d/zabbix.conf 

#启动服务
systemctl start httpd
systemctl enable httpd 

#数据库已设为UTF8，web端直接添加楷体字体，解决页面乱码
yum -y install wqy-microhei-fonts
wget ftp://172.25.254.250/notes/project/software/zabbix/simkai.ttf
cp /root/simkai.ttf /usr/share/zabbix/fonts/


sed -i "s/'graph')/'simkai')/" /usr/share/zabbix/include/defines.inc.php

systemctl restart httpd

       



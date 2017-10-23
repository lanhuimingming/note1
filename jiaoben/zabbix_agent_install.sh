#!/bin/bash
#获取软件
lftp 172.25.254.250:/notes/project/software/zabbix/zabbix3.2 <<EOT
get zabbix-agent-3.2.7-1.el7.x86_64.rpm
exit
EOT

#安装软件
cd zabbix3.2
rpm -ivh zabbix-agent-3.2.7-1.el7.x86_64.rpm 
yum -y install net-snmp net-snmp-utils


#修改配置文件
sed -i 's/^Server=.*/Server=172.25.9.11/'/etc/zabbix/zabbix_agentd.conf 
sed -i 's/^ServerActive=.*/ServerActive=172.25.9.11/'/etc/zabbix/zabbix_agentd.conf
sed -i 's/^Hostname=.*/Hostname=servera.prod9.example.com/'/etc/zabbix/zabbix_agentd.conf
sed -i 's/^#UnsafeUserParameters=0/UnsafeUserParameters=1/'/etc/zabbix/zabbix_agentd.conf

#启动服务
systemctl start zabbix-agent
systemctl enable zabbix-agent

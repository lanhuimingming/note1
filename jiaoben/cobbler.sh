#!/bin/bash
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
setenforce 0
sed -i 's/ONBOOT=yes/ONBOOT=no/' /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i '$a GATEWAY=192.168.0.10' /etc/sysconfig/network-scripts/ifcfg-eth1
service network restart
wget -r ftp://172.25.254.250/notes/project/software/cobbler_rhel7/
mv 172.25.254.250/notes/project/software/cobbler_rhel7/ cobbler
cd cobbler/
rpm -ivh python2-simplejson-3.10.0-1.el7.x86_64.rpm
rpm -ivh python-django-1.6.11.6-1.el7.noarch.rpm python-django-bash-completion-1.6.11.6-1.el7.noarch.rpm

yum localinstall cobbler-2.8.1-2.el7.x86_64.rpm cobbler-web-2.8.1-2.el7.noarch.rpm
systemctl start cobblerd
systemctl start httpd
systemctl enable httpd
systemctl enable cobblerd

sed -i '/server: 127.0.0.1/server: 192.168.0.11/' /etc/cobbler/settings
sed -i '/next_server: 127.0.0.1/next_server: 192.168.0.11/' /etc/cobbler/settings
setenforce 0
sed -i 's/disable.*/disable=no/' /etc/xinetd.d/tftp
yum -y install syslinux
systemctl start rsyncd
systemctl enable rsyncd
yum -y install pykickstart
openssl passwd -1 -salt 'random-phrase-here' 'redhat'
sed -i 's/default_password_crypted.*/default_password_crypted: "$1$random-p$MvGDzDfse5HkTwXB2OLNb."/' /etc/cobbler/settings
yum -y install fence-agents
mkdir /yum
mount -t nfs 172.25.254.250:/content /mnt/
mount -o loop /mnt/rhel7.2/x86_64/isos/rhel-server-7.2-x86_64-dvd.iso /yum/
cobbler import --path=/yum --name=rhel-server-7.2-base --arch=x86_64 && echo "yes"
yum -y install dhcp
\cp /root/dhcp.template /etc/cobbler/dhcp.template
sed -i 's/manage_dhcp: 0/manage_dhcp: 1/' /etc/cobbler/settings
systemctl restart cobblerd
cobbler sync
systemctl start dhcpd
systemctl restart xinetd
echo "yes"

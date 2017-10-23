#!/bin/bash
sed -i '$a GATEWAY=192.168.0.10' /etc/sysconfig/network-scripts/ifcfg-eth1
sed -i 's/ONBOOT=yes/ONBOOT=no/' /etc/sysconfig/network-scripts/ifcfg-eth0
systemctl restart network && echo "NETWORK SUCCESS!"
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
setenforce 0
mount -t nfs 172.25.254.250:/content /mnt/
mkdir /yum
mount -o loop /mnt/rhel7.1/x86_64/isos/rhel-server-7.1-x86_64-dvd.iso  /yum/
rm -rf /etc/yum.repos.d/*
cat > /etc/yum.repos.d/local.repo<<EOT
[local]
baseurl=file:///yum
gpgcheck=0
EOT

yum clean all && echo "clean yum success!"

yum -y install dhcp
\cp /usr/share/doc/dhcp-4.2.5/dhcpd.conf.example  /etc/dhcp/dhcpd.conf

> /etc/dhcp/dhcpd.conf
cat > /etc/dhcp/dhcpd.conf <<EOT
allow booting;
allow bootp;
option domain-name "pod1.example.com";
option domain-name-servers 172.25.254.254;
default-lease-time 600;
max-lease-time 7200;
log-facility local7;
subnet 192.168.0.0 netmask 255.255.255.0 {
  range 192.168.0.50 192.168.0.60;
  option domain-name-servers 172.25.254.254;
  option domain-name "pod0.example.com";
  option routers 192.168.0.10;
  option broadcast-address 192.168.0.255;
  default-lease-time 600;
  max-lease-time 7200;
  next-server 192.168.0.16;
  filename "pxelinux.0";
}
EOT
dhcpd -t
[ $? -eq 0 ] && systemctl start dhcpd


yum -y install tftp-server

yum -y install syslinux

cp /usr/share/syslinux/pxelinux.0  /var/lib/tftpboot/

cd /var/lib/tftpboot/
mkdir pxelinux.cfg
cd pxelinux.cfg
touch default

cat > /var/lib/tftpboot/pxelinux.cfg/default <<END
default vesamenu.c32
timeout 60
display boot.msg
menu background splash.jpg
menu title Welcome to Global Learning Services Setup!

label local
        menu label Boot from ^local drive
        menu default
        localhost 0xffff

label install
        menu label Install rhel7
        kernel vmlinuz
        append initrd=initrd.img ks=http://192.168.0.16/myks.cfg
END

cd /mnt/rhel7.1/x86_64/dvd/isolinux
cp splash.png vesamenu.c32 vmlinuz initrd.img /var/lib/tftpboot/
#sed -i 's/disable.*/disable=no/' /etc/xinetd.d/tftp
sed -i 's/disable.*/disable                 = no/' /etc/xinetd.d/tftp

systemctl start xinetd

yum -y install system-config-kickstart

yum -y install httpd

cat >/var/www/html/myks.cfg<<EOT
#version=RHEL7
# System authorization information
auth --enableshadow --passalgo=sha512
# Reboot after installation 
reboot
# Use network installation
url --url="http://192.168.0.16/rhel7u1/"
# Use graphical install
#graphical 
text
# Firewall configuration
firewall --enabled --service=ssh
firstboot --disable 
ignoredisk --only-use=vda
# Keyboard layouts
# old format: keyboard us
# new format:
keyboard --vckeymap=us --xlayouts='us'
# System language 
lang en_US.UTF-8
# Network information
network  --bootproto=dhcp
network  --hostname=localhost.localdomain
# Root password
rootpw --iscrypted nope 
# SELinux configuration
selinux --disabled
# System services
services --disabled="kdump,rhsmcertd" --enabled="network,sshd,rsyslog,ovirt-guest-agent,chronyd"
# System timezone
timezone Asia/Shanghai --isUtc
# System bootloader configuration
bootloader --append="console=tty0 crashkernel=auto" --location=mbr --timeout=1 --boot-drive=vda 
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all --initlabel
# Disk partitioning information
part / --fstype="xfs" --ondisk=vda --size=6144
%post
echo "redhat" | passwd --stdin root
useradd carol
echo "redhat" | passwd --stdin carol
# workaround anaconda requirements
%end

%packages
@core
%end
EOT

ln -s /yum/ /var/www/html/rhel7u1

mkdir -p /rhel6u5
mount /mnt/rhel6.5/x86_64/isos/rhel-server-6.5-x86_64-dvd.iso /rhel6u5/
ln -s /rhel6u5/ /var/www/html/rhel6u5
service httpd restart
cat >/var/www/html/rhel6u5_ks.cfg<<END
#platform=x86, AMD64, or Intel EM64T
#version=DEVEL
# Firewall configuration
firewall --disabled
# Install OS instead of upgrade
install
# Use network installation
url --url="http://192.168.0.16/rhel6u5"
# Root password
rootpw --plaintext redhat
# System authorization information
auth  --useshadow  --passalgo=sha512
# Use text mode install
text
firstboot --disable
# System keyboard
keyboard us
# System language
lang en_US
# SELinux configuration
selinux --disabled
# Installation logging level
logging --level=info
# Reboot after installation
reboot
# System timezone
timezone --isUtc Asia/Shanghai
# Network information
network  --bootproto=dhcp --device=eth0 --onboot=on
# System bootloader configuration
bootloader --location=mbr
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all --initlabel 
# Disk partitioning information
part /boot --fstype="ext4" --size=200
part / --fstype="ext4" --size=9000
part swap --fstype="swap" --size=1024

%pre
clearpart --all
part /boot --fstype ext4 --size=100
part pv.100000 --size=10000
part swap --size=512
volgroup vg --pesize=32768 pv.100000
logvol /home --fstype ext4 --name=lv_home --vgname=vg --size=480
logvol / --fstype ext4 --name=lv_root --vgname=vg --size=8192
%end


%post
touch /tmp/abc
%end

%packages
@base
@chinese-support
tigervnc
openssh-clients

%end
END
mkdir  -p /var/lib/tftpboot/rhel6u5
cd /mnt/rhel6.5/x86_64/dvd/isolinux/
cp vmlinuz initrd.img /var/lib/tftpboot/rhel6u5/
cat >>/var/lib/tftpboot/pxelinux.cfg/default<<END
label install6
        menu label Install rhel6u5
        kernel rhel6u5/vmlinuz
        append initrd=rhel6u5/initrd.img ks=http://192.168.0.16/rhel6u5_ks.cfg
label rescue
        menu label Install rescue
        kernel rhel6u5/vmlinuz
        append initrd=rhel6u5/initrd.img rescue

END

systemctl start httpd
systemctl enable xinetd
systemctl enable httpd
systemctl enable dhcpd

echo "yes"

#!/bin/bash
mkdir /mnt/usb
mount /dev/sda1  /mnt/usb/
rm -rf /etc/yum.repos.d/*
cat > /etc/yum.repos.d/base.repo<<END
[base]
baseurl=ftp://172.25.254.254/content/rhel6.5/x86_64/dvd
gpgcheck=0
END
yum -y install filesystem --installroot=/mnt/usb/
yum -y install bash coreutils findutils grep vim-enhanced rpm yum passwd net-tools util-linux lvm2 openssh-clients bind-utils --installroot=/mnt/usb/

cp -a /boot/vmlinuz-2.6.32-431.el6.x86_64 /mnt/usb/boot/
cp -a /boot/initramfs-2.6.32-431.el6.x86_64.img /mnt/usb/boot/
cp -arv /lib/modules/2.6.32-431.el6.x86_64/ /mnt/usb/lib/modules/

rpm -ivh http://172.25.254.254/content/rhel6.5/x86_64/dvd/Packages/grub-0.97-83.el6.x86_64.rpm --root=/mnt/usb/ --nodeps --force 

grub-install  --root-directory=/mnt/usb/ /dev/sda --recheck &>/dev/null && echo "驱动文件安装成功"

cp /boot/grub/grub.conf  /mnt/usb/boot/grub/

cat > /mnt/usb/boot/grub/grub.conf <<END
default=0
timeout=5
splashimage=/boot/grub/splash.xpm.gz
hiddenmenu
title My usb system from hugo
        root (hd0,0)
        kernel /boot/vmlinuz-2.6.32-431.el6.x86_64 ro root=UUID=b9159dca-252a-4919-bee1-5743d2d1bbd7 selinux=0 
        initrd /boot/initramfs-2.6.32-431.el6.x86_64.img
END
 
cp /boot/grub/splash.xpm.gz /mnt/usb/boot/grub/

cp /etc/skel/.bash* /mnt/usb/root/

cat > /mnt/usb/etc/sysconfig/network<<END
NETWORKING=yes
HOSTNAME=myusb.hugo.org
END

cp /etc/sysconfig/network-scripts/ifcfg-eth0 /mnt/usb/etc/sysconfig/network-scripts/
cat > /mnt/usb/etc/sysconfig/network-scripts/ifcfg-eth0<<END
DEVICE="eth0"
BOOTPROTO="static"
ONBOOT="yes"
IPADDR=192.168.0.109
NETMASK=255.255.255.0
GATEWAY=192.168.0.254
DNS1=8.8.8.8
END
#blkid  /dev/sda1
#/dev/sda1: UUID="b9159dca-252a-4919-bee1-5743d2d1bbd7" TYPE="ext4"
usbid=`blkid /dev/sda1| awk -F'"' '{print $2}'`
cat > /mnt/usb/etc/fstab<<END
UUID="$usbid" /  ext4 defaults 0 0
proc                    /proc                   proc    defaults        0 0
sysfs                   /sys                    sysfs   defaults        0 0
tmpfs                   /dev/shm                tmpfs   defaults        0 0
devpts                  /dev/pts                devpts  gid=5,mode=620  0 0
END
sed -i 's/^root.*/root:$1$HORgV/$uu5Ipz.4aRdZKCszBDput0:15937:0:99999:7:::/' /mnt/usb/etc/shadow
umount /mnt/usb/
echo "Make USB system success!"

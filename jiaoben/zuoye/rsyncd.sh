#!/bin/bash
setenfoce 0
yum -y install httpd
yum-y install rsync
mkdir /uplooking
chown apache.apache /uplooking/
chmod 770 /uplooking/

echo test >test.html

echo "123" >/root/.rsync_pass
chmod 600 /root/.rsync_pass

rsync -v 172.25.9.10:: && echo yes
rsync -v 172.25.9.11:: && echo yes
rsync -v 172.25.9.12:: && echo yes

#already make ssh-keygen

for i in {10..12};do ssh root@172.25.1.$i "cat /var/www/html/test.html"; done && echo "rsync is success! "


#!/bin/sh
for i in {11,12,13};do scp /home/kiosk/Desktop/jiaoben/rsync.sh root@172.25.9.$i:/root;
ssh root@172.25.9.$i "sh  /root/rsync.sh";done

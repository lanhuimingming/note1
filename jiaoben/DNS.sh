#!/bin/bash
setenforce 0
yum -y install bind 
cat >/etc/named.conf<<END
options {
	listen-on port 53 { 127.0.0.1; any; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	allow-query     { localhost; any; };
	recursion no;
	dnssec-enable no;
	dnssec-validation no;
	dnssec-lookaside auto;
	bindkeys-file "/etc/named.iscdlv.key";
	managed-keys-directory "/var/named/dynamic";
	pid-file "/run/named/named.pid";
	session-keyfile "/run/named/session.key";
};
logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};
view  dx {
        match-clients { 172.25.9.11; };
	zone "." IN {
		type hint;
		file "named.ca";
	};
	zone "lhm.com" IN {
		type master;
		file "lhm.com.dx.zone";	
	};
	include "/etc/named.rfc1912.zones";
};
view  wt {
        match-clients { 172.25.9.12; };
        zone "." IN {
                type hint;
                file "named.ca";
        };
        zone "lhm.com" IN {
                type master;
                file "lhm.com.wt.zone";
        };
	include "/etc/named.rfc1912.zones";
};
view  other {
        match-clients { any; };
        zone "." IN {
                type hint;
                file "named.ca";
        };
        zone "lhm.com" IN {
                type master;
                file "lhm.com.other.zone";
        };
        include "/etc/named.rfc1912.zones";
};
include "/etc/named.root.key";
END

cp /var/named/named.localhost lhm.com.dx.zone
cp /var/named/named.localhost lhm.com.wt.zone
cp /var/named/named.localhost lhm.com.other.zone

cat >/var/named/lhm.com.dx.zone<<END
\$TTL 1D
@	IN SOA	ns1.lhm.com. rname.invalid. (
					10	; serial
					1D	; refresh
					1H	; retry
					1W	; expire
					3H )	; minimum
@	NS	ns1.lhm.com.
ns1     A       172.25.9.10
www	A	192.168.11.1
END
cat >/var/name/lhm.com.dx.zone<<END
\$TTL 1D
@	IN SOA	ns1.lhm.com. rname.invalid. (
					10	; serial
					1D	; refresh
					1H	; retry
					1W	; expire
					3H )	; minimum
@	NS	ns1.lhm.com.
ns1     A       172.25.9.10
www	A	22.21.1.1
END
cat >/var/name/lhm.com.dx.zone<<END
\$TTL 1D
@	IN SOA	ns1.lhm.com. rname.invalid. (
					10	; serial
					1D	; refresh
					1H	; retry
					1W	; expire
					3H )	; minimum
@	NS	ns1.lhm.com.
ns1     A       172.25.9.10
www	A	1.1.1.1
END

chgrp named /var/named/lhm.com.*

systemctl start named
systemctl enable named



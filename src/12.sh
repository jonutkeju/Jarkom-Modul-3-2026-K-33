#UTAHIME
cat << 'EOF' > /root/setup.sh
#!/bin/sh
while ! ping -c 1 -W 1 10.80.1.1 >/dev/null 2>&1; do sleep 1; done

if ! which named >/dev/null 2>&1; then
    rm -rf /etc/apt/sources.list.d/*
    echo "deb [trusted=yes check-valid-until=no] http://deb.debian.org/debian trixie main" > /etc/apt/sources.list
    apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false
    apt-get install -y --allow-unauthenticated bind9 bind9utils dnsutils
fi

# 1. Konfigurasi options (DNS Forwarder ke NAT Gateway 192.168.122.1)
cat << 'CONFIG' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    forwarders {
        192.168.122.1;
    };
    allow-query { any; };
    auth-nxdomain no;
    listen-on-v6 { any; };
};
CONFIG

# 2. Deklarasi Forward Zone dan Reverse Zone di named.conf.local
cat << 'CONFIG' > /etc/bind/named.conf.local
zone "jujutsu.Kel33.com" {
    type master;
    file "/etc/bind/db.jujutsu.Kel33.com";
    allow-transfer { 10.80.1.3; };
    also-notify { 10.80.1.3; };
};

zone "1.80.10.in-addr.arpa" {
    type master;
    file "/etc/bind/db.10.80.1";
    allow-transfer { 10.80.1.3; };
    also-notify { 10.80.1.3; };
};
CONFIG

# 3. Buat File Forward Zone db.jujutsu.Kel33.com (A Record @ mengarah ke Gojo 10.80.1.4, CNAME www)
cat << 'CONFIG' > /etc/bind/db.jujutsu.Kel33.com
$TTL    604800
@       IN      SOA     utahime.jujutsu.Kel33.com. root.jujutsu.Kel33.com. (
                              2026101502 ; Serial (Naikkan serial)
                                  604800 ; Refresh
                                   86400 ; Retry
                                 2419200 ; Expire
                                  604800 ) ; Negative Cache TTL
;
@       IN      NS      utahime.jujutsu.Kel33.com.
@       IN      NS      shoko.jujutsu.Kel33.com.

; A Records
@       IN      A       10.80.1.4
utahime IN      A       10.80.1.2
shoko   IN      A       10.80.1.3
gojo    IN      A       10.80.1.4
geto    IN      A       10.80.4.20

; CNAME Record
www     IN      CNAME   jujutsu.Kel33.com.
CONFIG

# 4. Buat File Reverse Zone db.10.80.1 (PTR Record untuk IP Gojo 10.80.1.4)
cat << 'CONFIG' > /etc/bind/db.10.80.1
$TTL    604800
@       IN      SOA     utahime.jujutsu.Kel33.com. root.jujutsu.Kel33.com. (
                              2026101502 ; Serial
                                  604800 ; Refresh
                                   86400 ; Retry
                                 2419200 ; Expire
                                  604800 ) ; Negative Cache TTL
;
@       IN      NS      utahime.jujutsu.Kel33.com.
@       IN      NS      shoko.jujutsu.Kel33.com.

; PTR Records (10.80.1.4 -> gojo.jujutsu.Kel33.com.)
4       IN      PTR     gojo.jujutsu.Kel33.com.
CONFIG

# Restart / Reload Service BIND9
/etc/init.d/named restart 2>/dev/null || /etc/init.d/bind9 restart 2>/dev/null
rndc reload 2>/dev/null
EOF

chmod +x /root/setup.sh
/root/setup.sh

#SHOKO
#!/bin/sh
cat << 'EOF' > /root/setup.sh
#!/bin/sh
while ! ping -c 1 -W 1 10.80.1.1 >/dev/null 2>&1; do sleep 1; done

if ! which named >/dev/null 2>&1; then
    rm -rf /etc/apt/sources.list.d/*
    echo "deb [trusted=yes check-valid-until=no] http://deb.debian.org/debian trixie main" > /etc/apt/sources.list
    apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false
    apt-get install -y --allow-unauthenticated bind9 bind9utils dnsutils
fi

cat << 'CONFIG' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    forwarders {
        192.168.122.1;
    };
    allow-query { any; };
    auth-nxdomain no;
    listen-on-v6 { any; };
};
CONFIG

cat << 'CONFIG' > /etc/bind/named.conf.local
zone "jujutsu.Kel33.com" {
    type slave;
    file "/var/cache/bind/db.jujutsu.Kel33.com";
    masters { 10.80.1.2; };
    masterfile-format text;
};

zone "1.80.10.in-addr.arpa" {
    type slave;
    file "/var/cache/bind/db.10.80.1";
    masters { 10.80.1.2; };
    masterfile-format text;
};
CONFIG

rm -f /var/cache/bind/db.*
/etc/init.d/named restart 2>/dev/null || /etc/init.d/bind9 restart 2>/dev/null
EOF

chmod +x /root/setup.sh
/root/setup.sh

#TESTING DI ITADORI
cat << 'EOF' > /root/test_soal12.sh
#!/bin/sh

if ! command -v dig >/dev/null 2>&1; then
    apk add --no-cache bind-tools >/dev/null 2>&1
fi

DNS_SERVER="10.80.1.2"
DOMAIN="jujutsu.Kel33.com"

echo "=================================================="
echo "          TESTING DNS SOAL 12 (BIND9)             "
echo "=================================================="
echo ""

# 1. Cek A Record Domain Utama (jujutsu.Kel33.com -> 10.80.1.4)
echo "[1] Testing Domain Utama A Record ($DOMAIN)..."
A_REC=$(dig @$DNS_SERVER $DOMAIN A +short 2>/dev/null)
echo "Result A Record : $A_REC"
if [ "$A_REC" = "10.80.1.4" ]; then
    echo "Status          : [ OK ] Domain utama mengarah ke Gojo (10.80.1.4)"
else
    echo "Status          : [ FAIL ] Domain utama tidak mengarah ke 10.80.1.4"
fi
echo ""

# 2. Cek CNAME www.jujutsu.Kel33.com -> jujutsu.Kel33.com
echo "[2] Testing CNAME Record (www.$DOMAIN)..."
CNAME_REC=$(dig @$DNS_SERVER www.$DOMAIN CNAME +short 2>/dev/null)
echo "Result CNAME    : $CNAME_REC"
if echo "$CNAME_REC" | grep -q "$DOMAIN"; then
    echo "Status          : [ OK ] CNAME www merujuk ke domain utama"
else
    echo "Status          : [ FAIL ] CNAME www salah/tidak ditemukan"
fi
echo ""

# 3. Cek Reverse DNS / PTR Record (10.80.1.4 -> gojo.jujutsu.Kel33.com)
echo "[3] Testing Reverse DNS PTR Record (10.80.1.4)..."
PTR_REC=$(dig @$DNS_SERVER -x 10.80.1.4 +short 2>/dev/null)
echo "Result PTR      : $PTR_REC"
if echo "$PTR_REC" | grep -q "gojo.$DOMAIN"; then
    echo "Status          : [ OK ] Reverse IP 10.80.1.4 berhasil melacak ke Gojo"
else
    echo "Status          : [ FAIL ] PTR Record tidak cocok"
fi
echo ""

# 4. Cek Forwarder Internet (Ping google.com)
echo "[4] Testing DNS Forwarder & Internet Access (google.com)..."
if ping -c 2 google.com >/dev/null 2>&1; then
    echo "Status          : [ OK ] Client berhasil meresolusi & ping google.com"
else
    echo "Status          : [ FAIL ] Forwarder internet tidak berjalan"
fi

echo "=================================================="
EOF

chmod +x /root/test_soal12.sh
/root/test_soal12.sh

#TES MANUAL
#Cek A Record Domain Utama
dig @10.80.1.2 jujutsu.Kel33.com A +short
#10.80.1.4
#Cek CNAME Record
dig @10.80.1.2 www.jujutsu.Kel33.com CNAME +short
#jujutsu.Kel33.com.
#Cek Reverse DNS / PTR Record
dig @10.80.1.2 -x 10.80.1.4 +short
#gojo.jujutsu.Kel33.com.
#Cek DNS Forwarder & Akses Internet
#Tes Resolusi DNS Domain Luar
dig @10.80.1.2 google.com A +short
#142.250.199.14
#Tes Ping Langsung ke Domain Luar
ping -c 2 google.com
#PING google.com (142.250.199.14): 56 data bytes
#64 bytes from 142.250.199.14: seq=0 ttl=115 time=12.451 ms
#64 bytes from 142.250.199.14: seq=1 ttl=115 time=11.820 ms

#--- google.com ping statistics ---
#2 packets transmitted, 2 packets received, 0% packet loss

#kalau tidak bisa ping google.com
nano /etc/resolv.conf
#isi ini
nameserver 10.80.1.2
nameserver 10.80.1.3
#lalu
cat /etc/resolv.conf
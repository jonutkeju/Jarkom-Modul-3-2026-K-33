#UTAHIME
#!/bin/sh
cat << 'EOF' > /root/setup.sh
#!/bin/sh
# Pastikan repository dan koneksi jalan
while ! ping -c 1 -W 1 10.80.1.1 >/dev/null 2>&1; do sleep 1; done

if ! which named >/dev/null 2>&1; then
    rm -rf /etc/apt/sources.list.d/*
    echo "deb [trusted=yes check-valid-until=no] http://deb.debian.org/debian trixie main" > /etc/apt/sources.list
    apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false
    apt-get install -y --allow-unauthenticated bind9 bind9utils dnsutils
fi

# 1. Konfigurasi options (disable DNSSEC validation jika perlu/opsional, allow-query)
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

# 2. Deklarasi Zone Master pada named.conf.local
cat << 'CONFIG' > /etc/bind/named.conf.local
zone "jujutsu.Kel33.com" {
    type master;
    file "/etc/bind/db.jujutsu.Kel33.com";
    allow-transfer { 10.80.1.3; }; // Mengizinkan shoko (Slave) untuk Zone Transfer
    also-notify { 10.80.1.3; };
};
CONFIG

# 3. Buat File DB Zone
cat << 'CONFIG' > /etc/bind/db.jujutsu.Kel33.com
$TTL    604800
@       IN      SOA     utahime.jujutsu.Kel33.com. root.jujutsu.Kel33.com. (
                              2026101501 ; Serial (YYYYMMDDNN)
                                  604800 ; Refresh
                                   86400 ; Retry
                                 2419200 ; Expire
                                  604800 ) ; Negative Cache TTL
;
; Name Servers
@       IN      NS      utahime.jujutsu.Kel33.com.
@       IN      NS      shoko.jujutsu.Kel33.com.

; A Records
@       IN      A       10.80.1.2
utahime IN      A       10.80.1.2
shoko   IN      A       10.80.1.3
gojo    IN      A       10.80.1.4
geto    IN      A       10.80.4.20
CONFIG

# Restart service BIND9
/etc/init.d/named restart 2>/dev/null || /etc/init.d/bind9 restart 2>/dev/null
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

# 1. Konfigurasi options
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

# 2. Deklarasi Zone Slave pada named.conf.local
cat << 'CONFIG' > /etc/bind/named.conf.local
zone "jujutsu.Kel33.com" {
    type slave;
    file "/var/cache/bind/db.jujutsu.Kel33.com";
    masters { 10.80.1.2; }; // IP utahime (Master)
};
CONFIG

# Restart service BIND9
/etc/init.d/named restart 2>/dev/null || /etc/init.d/bind9 restart 2>/dev/null
EOF

chmod +x /root/setup.sh
/root/setup.sh

#CEK KELAYAKAN SYNTAX KONFIGURASI DI UTAHIME
named-checkconf
named-checkzone jujutsu.Kel33.com /etc/bind/db.jujutsu.Kel33.com  # (Jalankan di utahime)

#CEK TERBUATNYA FILE REPLIKA DI SHOKO
ls -la /var/cache/bind/

#SCRIPT TESTING DI ITADORI
cat << 'EOF' > /root/test_soal11.sh
#!/bin/sh

if ! command -v dig >/dev/null 2>&1; then
    apk add --no-cache bind-tools >/dev/null 2>&1
fi

MASTER_IP="10.80.1.2"
SLAVE_IP="10.80.1.3"
DOMAIN="jujutsu.Kel33.com"

echo "=================================================="
echo "          TESTING DNS SOAL 11 (BIND9)             "
echo "=================================================="
echo ""

echo "[1] Testing DNS Master (utahime - $MASTER_IP)..."
dig @$MASTER_IP $DOMAIN NS +short 2>/dev/null
dig @$MASTER_IP utahime.$DOMAIN A +short 2>/dev/null
dig @$MASTER_IP shoko.$DOMAIN A +short 2>/dev/null
dig @$MASTER_IP gojo.$DOMAIN A +short 2>/dev/null
echo ""

echo "[2] Testing DNS Slave (shoko - $SLAVE_IP)..."
dig @$SLAVE_IP $DOMAIN NS +short 2>/dev/null
dig @$SLAVE_IP utahime.$DOMAIN A +short 2>/dev/null
dig @$SLAVE_IP shoko.$DOMAIN A +short 2>/dev/null
dig @$SLAVE_IP gojo.$DOMAIN A +short 2>/dev/null
echo ""

echo "[3] Checking SOA Serial Synchronization..."
SERIAL_MASTER=$(dig @$MASTER_IP $DOMAIN SOA +short 2>/dev/null | awk '{print $3}')
SERIAL_SLAVE=$(dig @$SLAVE_IP $DOMAIN SOA +short 2>/dev/null | awk '{print $3}')

echo "Master Serial : $SERIAL_MASTER"
echo "Slave Serial  : $SERIAL_SLAVE"

if [ -n "$SERIAL_MASTER" ] && [ "$SERIAL_MASTER" = "$SERIAL_SLAVE" ]; then
    echo "STATUS        : [ SUCCESS ] Zone Transfer & Replikasi Berhasil!"
else
    echo "STATUS        : [ FAILED ] Serial Mismatch / Network Unreachable."
fi
echo "=================================================="
EOF

chmod +x /root/test_soal11.sh
/root/test_soal11.sh

#PASANG IP STATIS SEMENTARA DI ITADORI
# 1. Pasang IP untuk itadori (subnet Network 2)
ip addr add 10.80.2.10/24 dev eth0

# 2. Tambahkan Default Gateway mengarah ke router jichi
ip route add default via 10.80.2.1 dev eth0

# 3. Cek koneksi ping ke router jichi dan DNS Master (utahime)
ping -c 2 10.80.2.1
ping -c 2 10.80.1.2

#JALANKAN KEMBALI UJI COBA SCRIPT DI ITADORI
/root/test_soal11.sh


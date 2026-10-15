#NANAMI
cat << 'EOF' > /root/setup.sh
#!/bin/sh

# 1. Network Persistent
ip addr del 10.80.4.22/24 dev eth0 2>/dev/null
ip addr add 10.80.4.21/24 dev eth0 2>/dev/null
ip link set eth0 up
ip route add default via 10.80.4.1 dev eth0 2>/dev/null

# 2. DNS & Install Nginx jika belum ada
echo "nameserver 192.168.122.1" > /etc/resolv.conf
if ! which nginx >/dev/null 2>&1; then
    rm -rf /etc/apt/sources.list.d/*
    echo "deb [trusted=yes check-valid-until=no] http://deb.debian.org/debian trixie main" > /etc/apt/sources.list
    apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false
    apt-get install -y --allow-unauthenticated nginx curl
fi

# 3. Buat Folder Respon & Direktori Nginx
mkdir -p /var/www/api /etc/nginx/sites-available /etc/nginx/sites-enabled
echo '{"status":"success","worker":"nanami"}' > /var/www/api/index.html
echo '{"status":"success","worker":"nanami"}' > /var/www/api/index.php

# 4. Konfigurasi VHost Nginx
cat << 'CONFIG' > /etc/nginx/sites-available/api
server {
    listen 80;
    server_name _;
    root /var/www/api;
    index index.html index.php;

    allow 10.80.4.0/24;
    deny all;

    location / {
        try_files $uri $uri/ =404;
    }
}
CONFIG

ln -sf /etc/nginx/sites-available/api /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 5. Restart Service
/etc/init.d/nginx restart 2>/dev/null || service nginx restart 2>/dev/null
echo "[SUCCESS] nanami Configured & Persistent!"
EOF

chmod +x /root/setup.sh
/root/setup.sh

#TODO
ccat << 'EOF' > /root/setup.sh
#!/bin/sh

# 1. Network Persistent
ip addr del 10.80.4.21/24 dev eth0 2>/dev/null
ip addr add 10.80.4.22/24 dev eth0 2>/dev/null
ip link set eth0 up
ip route add default via 10.80.4.1 dev eth0 2>/dev/null

# 2. DNS & Install Nginx jika belum ada
echo "nameserver 192.168.122.1" > /etc/resolv.conf
if ! which nginx >/dev/null 2>&1; then
    rm -rf /etc/apt/sources.list.d/*
    echo "deb [trusted=yes check-valid-until=no] http://deb.debian.org/debian trixie main" > /etc/apt/sources.list
    apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false
    apt-get install -y --allow-unauthenticated nginx curl
fi

# 3. Buat Folder Respon & Direktori Nginx
mkdir -p /var/www/api /etc/nginx/sites-available /etc/nginx/sites-enabled
echo '{"status":"success","worker":"todo"}' > /var/www/api/index.html
echo '{"status":"success","worker":"todo"}' > /var/www/api/index.php

# 4. Konfigurasi VHost Nginx
cat << 'CONFIG' > /etc/nginx/sites-available/api
server {
    listen 80;
    server_name _;
    root /var/www/api;
    index index.html index.php;

    allow 10.80.4.0/24;
    deny all;

    location / {
        try_files $uri $uri/ =404;
    }
}
CONFIG

ln -sf /etc/nginx/sites-available/api /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 5. Restart Service
/etc/init.d/nginx restart 2>/dev/null || service nginx restart 2>/dev/null
echo "[SUCCESS] todo Configured & Persistent!"
EOF

chmod +x /root/setup.sh
/root/setup.sh

#GETO SETUP
cat << 'EOF' > /root/setup.sh
#!/bin/sh

# 1. Konfigurasi Network Persistent
ip addr add 10.80.4.20/24 dev eth0 2>/dev/null
ip link set eth0 up
ip route add default via 10.80.4.1 dev eth0 2>/dev/null

# 2. DNS Resolv agar APT aman
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# 3. Instalasi Nginx jika belum ada
if ! which nginx >/dev/null 2>&1; then
    rm -rf /etc/apt/sources.list.d/*
    echo "deb [trusted=yes check-valid-until=no] http://deb.debian.org/debian trixie main" > /etc/apt/sources.list
    apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false
    apt-get install -y --allow-unauthenticated nginx curl
fi

# 4. Konfigurasi Load Balancer Persistent (max_fails=0 & timeout)
mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
cat << 'CONFIG' > /etc/nginx/sites-available/load-balancer
upstream api_cluster {
    server 10.80.4.21:80 weight=3 max_fails=0; # nanami
    server 10.80.4.22:80 weight=1 max_fails=0; # todo
}

server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://api_cluster;
        proxy_connect_timeout 5s;
        proxy_read_timeout 5s;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
CONFIG

ln -sf /etc/nginx/sites-available/load-balancer /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 5. Restart Service
/etc/init.d/nginx restart 2>/dev/null || service nginx restart 2>/dev/null
echo "[SUCCESS] geto Configured & Persistent!"
EOF

chmod +x /root/setup.sh
/root/setup.sh

#UJI OTOMATIS
cat << 'EOF' > /root/test_soal15.sh
#!/bin/sh

GETO_IP="10.80.4.20"
TOTAL_REQUESTS=12

echo "=================================================="
echo "    PEMBUKTIAN LOAD BALANCER GETO (SOAL NO 15)    "
echo "=================================================="
echo ""
echo "[+] Mengirim $TOTAL_REQUESTS request ke Internal Load Balancer ($GETO_IP)..."
echo ""

NANAMI_COUNT=0
TODO_COUNT=0

for i in $(seq 1 $TOTAL_REQUESTS); do
    RESPONSE=$(curl -s http://$GETO_IP)

    if echo "$RESPONSE" | grep -qi "nanami"; then
        NANAMI_COUNT=$((NANAMI_COUNT + 1))
        echo "Request #$i -> Processed by: nanami"
    elif echo "$RESPONSE" | grep -qi "todo"; then
        TODO_COUNT=$((TODO_COUNT + 1))
        echo "Request #$i -> Processed by: todo"
    else
        echo "Request #$i -> Unknown Response: $RESPONSE"
    fi
    sleep 0.2
done

echo ""
echo "--------------------------------------------------"
echo "HASIL DISTRIBUSI BEBAN (Total: $TOTAL_REQUESTS Request):"
echo "  - nanami : $NANAMI_COUNT request"
echo "  - todo   : $TODO_COUNT request"
echo "--------------------------------------------------"

if [ $NANAMI_COUNT -gt $TODO_COUNT ]; then
    echo "STATUS : [ SUCCESS ] Weighted Round Robin (3:1) Berjalan Sesuai Target!"
else
    echo "STATUS : [ FAILED ] Distribusi Beban Tidak Sesuai Bobot!"
fi
echo "=================================================="
EOF

chmod +x /root/test_soal15.sh
/root/test_soal15.sh



#RESTART DAN TES ULANG
/etc/init.d/nginx restart
/root/test_soal15.sh
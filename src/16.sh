#MAKI
cat << 'EOF' > /root/setup.sh
#!/bin/sh

# 1. IP & Route Persistent
ip addr del 10.80.4.12/24 dev eth0 2>/dev/null
ip addr add 10.80.4.11/24 dev eth0 2>/dev/null
ip link set eth0 up
ip route add default via 10.80.4.1 dev eth0 2>/dev/null

# 2. Install Nginx jika belum ada
echo "nameserver 192.168.122.1" > /etc/resolv.conf
if ! which nginx >/dev/null 2>&1; then
    rm -rf /etc/apt/sources.list.d/*
    echo "deb [trusted=yes check-valid-until=no] http://deb.debian.org/debian trixie main" > /etc/apt/sources.list
    apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false
    apt-get install -y --allow-unauthenticated nginx curl
fi

# 3. Direktori & Konten
mkdir -p /var/www/frontend /etc/nginx/sites-available /etc/nginx/sites-enabled
echo "<h1>Hello from Frontend Worker: maki</h1>" > /var/www/frontend/index.html

# 4. Konfigurasi VHost
cat << 'CONFIG' > /etc/nginx/sites-available/frontend
server {
    listen 80;
    server_name _;
    root /var/www/frontend;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
CONFIG

ln -sf /etc/nginx/sites-available/frontend /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

/etc/init.d/nginx restart 2>/dev/null || service nginx restart 2>/dev/null
echo "[SUCCESS] maki Ready!"
EOF

chmod +x /root/setup.sh
/root/setup.sh

#PANDA
cat << 'EOF' > /root/setup.sh
#!/bin/sh

# 1. IP & Route Persistent
ip addr del 10.80.4.11/24 dev eth0 2>/dev/null
ip addr add 10.80.4.12/24 dev eth0 2>/dev/null
ip link set eth0 up
ip route add default via 10.80.4.1 dev eth0 2>/dev/null

# 2. Install Nginx jika belum ada
echo "nameserver 192.168.122.1" > /etc/resolv.conf
if ! which nginx >/dev/null 2>&1; then
    rm -rf /etc/apt/sources.list.d/*
    echo "deb [trusted=yes check-valid-until=no] http://deb.debian.org/debian trixie main" > /etc/apt/sources.list
    apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false
    apt-get install -y --allow-unauthenticated nginx curl
fi

# 3. Direktori & Konten
mkdir -p /var/www/frontend /etc/nginx/sites-available /etc/nginx/sites-enabled
echo "<h1>Hello from Frontend Worker: panda</h1>" > /var/www/frontend/index.html

# 4. Konfigurasi VHost
cat << 'CONFIG' > /etc/nginx/sites-available/frontend
server {
    listen 80;
    server_name _;
    root /var/www/frontend;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
CONFIG

ln -sf /etc/nginx/sites-available/frontend /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

/etc/init.d/nginx restart 2>/dev/null || service nginx restart 2>/dev/null
echo "[SUCCESS] panda Ready!"
EOF

chmod +x /root/setup.sh
/root/setup.sh


#GOJO
#cat << 'EOF' > /root/setup.sh
#!/bin/sh

# 1. IP & Route Persistent
ip addr add 10.80.1.4/24 dev eth0 2>/dev/null
ip link set eth0 up
ip route add default via 10.80.1.1 dev eth0 2>/dev/null

# 2. Install Nginx jika belum ada
echo "nameserver 192.168.122.1" > /etc/resolv.conf
if ! which nginx >/dev/null 2>&1; then
    rm -rf /etc/apt/sources.list.d/*
    echo "deb [trusted=yes check-valid-until=no] http://deb.debian.org/debian trixie main" > /etc/apt/sources.list
    apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false
    apt-get install -y --allow-unauthenticated nginx curl
fi

# 3. Direktori & Konfigurasi Reverse Proxy Path-Based Routing
mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
cat << 'CONFIG' > /etc/nginx/sites-available/jujutsu
upstream web_frontend {
    server 10.80.4.11:80 max_fails=0;
    server 10.80.4.12:80 max_fails=0;
}

upstream api_backend {
    server 10.80.4.20:80 max_fails=0;
}

server {
    listen 80 default_server;
    server_name jujutsu.Kel33.com www.jujutsu.Kel33.com;

    location / {
        proxy_pass http://web_frontend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /api {
        proxy_pass http://api_backend/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
CONFIG

ln -sf /etc/nginx/sites-available/jujutsu /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

/etc/init.d/nginx restart 2>/dev/null || service nginx restart 2>/dev/null
echo "[SUCCESS] gojo Configured & Persistent!"
EOF

chmod +x /root/setup.sh
/root/setup.sh

#ITADORI
cat << 'EOF' > /root/setup.sh
#!/bin/sh

# 1. Set IP dan Route via Router jichi
ip addr add 10.80.2.2/24 dev eth0 2>/dev/null
ip link set eth0 up
ip route del default 2>/dev/null
ip route add default via 10.80.2.1 dev eth0

# 2. Host Mapping ke IP Gojo
sed -i '/jujutsu.Kel33.com/d' /etc/hosts
echo "10.80.1.4 jujutsu.Kel33.com www.jujutsu.Kel33.com" >> /etc/hosts

echo "[SUCCESS] itadori Configured!"
EOF

chmod +x /root/setup.sh
/root/setup.sh

#TEST DI ITADORI
cat << 'EOF' > /root/test_soal16.sh
#!/bin/sh

DOMAIN="jujutsu.Kel33.com"

echo "=================================================="
echo "    PEMBUKTIAN PATH-BASED ROUTING (SOAL NO 16)    "
echo "=================================================="
echo ""

echo "[1] Testing Root Path (http://$DOMAIN/)..."
RES_ROOT1=$(curl -s http://$DOMAIN/)
RES_ROOT2=$(curl -s http://$DOMAIN/)

echo "    Request #1 -> $RES_ROOT1"
echo "    Request #2 -> $RES_ROOT2"

if echo "$RES_ROOT1 $RES_ROOT2" | grep -qi "maki" || echo "$RES_ROOT1 $RES_ROOT2" | grep -qi "panda"; then
    echo "    Status : [ SUCCESS ] Root Path Served by Frontend Workers!"
else
    echo "    Status : [ FAILED ] Root Path Error!"
fi
echo ""

echo "[2] Testing API Path (http://$DOMAIN/api)..."
RES_API1=$(curl -s http://$DOMAIN/api)
RES_API2=$(curl -s http://$DOMAIN/api)

echo "    Request #1 -> $RES_API1"
echo "    Request #2 -> $RES_API2"

if echo "$RES_API1 $RES_API2" | grep -qi "nanami" || echo "$RES_API1 $RES_API2" | grep -qi "todo"; then
    echo "    Status : [ SUCCESS ] API Path Served by Backend Workers via Geto!"
else
    echo "    Status : [ FAILED ] API Path Error!"
fi
echo "=================================================="
EOF

chmod +x /root/test_soal16.sh
/root/test_soal16.sh
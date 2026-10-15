#MAKI & PANDA
cat << 'EOF' > /root/setup.sh
#!/bin/sh
while ! ping -c 1 -W 1 10.80.4.1 >/dev/null 2>&1; do sleep 1; done

if ! which nginx >/dev/null 2>&1; then
    rm -rf /etc/apt/sources.list.d/*
    echo "deb [trusted=yes check-valid-until=no] http://deb.debian.org/debian trixie main" > /etc/apt/sources.list
    apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false
    apt-get install -y --allow-unauthenticated nginx php-fpm
fi

# 1. Halaman Frontend yang menampilkan Hostname
mkdir -p /var/www/frontend
cat << 'PHP' > /var/www/frontend/index.php
<?php
echo "<h1>Hello from Frontend Worker: " . gethostname() . "</h1>";
?>
PHP

# 2. Virtual Host Nginx dengan Pembatasan Akses (Hanya izinkan Gojo 10.80.1.4)
cat << 'CONFIG' > /etc/nginx/sites-available/frontend
server {
    listen 80;
    server_name _;

    root /var/www/frontend;
    index index.php index.html;

    # Pembatasan Akses: Hanya Gojo yang diperbolehkan
    allow 10.80.1.4;
    deny all;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
CONFIG

ln -sf /etc/nginx/sites-available/frontend /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

/etc/init.d/php8.2-fpm restart 2>/dev/null || /etc/init.d/php-fpm restart 2>/dev/null
/etc/init.d/nginx restart 2>/dev/null
EOF

chmod +x /root/setup.sh
/root/setup.sh

#NANAMI, TODO, KIRARA
cat << 'EOF' > /root/setup.sh
#!/bin/sh
while ! ping -c 1 -W 1 10.80.4.1 >/dev/null 2>&1; do sleep 1; done

if ! which nginx >/dev/null 2>&1; then
    rm -rf /etc/apt/sources.list.d/*
    echo "deb [trusted=yes check-valid-until=no] http://deb.debian.org/debian trixie main" > /etc/apt/sources.list
    apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false
    apt-get install -y --allow-unauthenticated nginx php-fpm php-mysql
fi

# 1. Aplikasi API yang mencatat log ke Database yaga (10.80.4.30)
mkdir -p /var/www/api
cat << 'PHP' > /var/www/api/index.php
<?php
header('Content-Type: application/json');

$host = '10.80.4.30';
$db   = 'db_shibuya_Kel33';
$user = 'shibuya_user';
$pass = 'CHANGE_ME_SHIBUYA_PASSWORD';

$client_ip = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'];
$hostname  = gethostname();

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8", $user, $pass);
    $stmt = $pdo->prepare("INSERT INTO request_logs (client_ip, message) VALUES (?, ?)");
    $stmt->execute([$client_ip, "API Request processed by worker: $hostname"]);

    echo json_encode([
        "status" => "success",
        "worker" => $hostname,
        "client_ip" => $client_ip,
        "message" => "Log successfully recorded to DB yaga"
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
PHP

# 2. Virtual Host Nginx dengan Pembatasan Akses (Hanya izinkan Geto 10.80.4.20)
cat << 'CONFIG' > /etc/nginx/sites-available/api
server {
    listen 80;
    server_name _;

    root /var/www/api;
    index index.php;

    # Pembatasan Akses: Hanya Geto yang diperbolehkan
    allow 10.80.4.20;
    deny all;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
CONFIG

ln -sf /etc/nginx/sites-available/api /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

/etc/init.d/php8.2-fpm restart 2>/dev/null || /etc/init.d/php-fpm restart 2>/dev/null
/etc/init.d/nginx restart 2>/dev/null
EOF

chmod +x /root/setup.sh
/root/setup.sh

#UJI OTOMATIS DI CLIENT EX: ITADORI
cat << 'EOF' > /root/test_soal14.sh
#!/bin/sh

echo "=================================================="
echo "    PEMBUKTIAN PEMBATASAN AKSES WORKER (SOAL 14)  "
echo "=================================================="
echo ""

# List IP Worker
MAKI_IP="10.80.4.11"
PANDA_IP="10.80.4.12"
NANAMI_IP="10.80.4.21"
TODO_IP="10.80.4.22"
KIRARA_IP="10.80.4.23"

# 1. Tes Akses Langsung ke Web Frontend (Maki & Panda)
echo "[1] Testing Direct Access to Web Frontend Workers (Should be 403 Forbidden)..."
HTTP_MAKI=$(curl -s -o /dev/null -w "%{http_code}" http://$MAKI_IP)
HTTP_PANDA=$(curl -s -o /dev/null -w "%{http_code}" http://$PANDA_IP)

echo "    Direct Access to maki ($MAKI_IP)  : HTTP $HTTP_MAKI"
echo "    Direct Access to panda ($PANDA_IP) : HTTP $HTTP_PANDA"

if [ "$HTTP_MAKI" = "403" ] && [ "$HTTP_PANDA" = "403" ]; then
    echo "    Status : [ SUCCESS ] Direct Access to Web Workers Blocked!"
else
    echo "    Status : [ FAILED ] Web Workers are accessible directly!"
fi
echo ""

# 2. Tes Akses Langsung ke API Workers (Nanami, Todo, Kirara)
echo "[2] Testing Direct Access to API Workers (Should be 403 Forbidden)..."
HTTP_NANAMI=$(curl -s -o /dev/null -w "%{http_code}" http://$NANAMI_IP)
HTTP_TODO=$(curl -s -o /dev/null -w "%{http_code}" http://$TODO_IP)
HTTP_KIRARA=$(curl -s -o /dev/null -w "%{http_code}" http://$KIRARA_IP)

echo "    Direct Access to nanami ($NANAMI_IP) : HTTP $HTTP_NANAMI"
echo "    Direct Access to todo ($TODO_IP)   : HTTP $HTTP_TODO"
echo "    Direct Access to kirara ($KIRARA_IP) : HTTP $HTTP_KIRARA"

if [ "$HTTP_NANAMI" = "403" ] && [ "$HTTP_TODO" = "403" ] && [ "$HTTP_KIRARA" = "403" ]; then
    echo "    Status : [ SUCCESS ] Direct Access to API Workers Blocked!"
else
    echo "    Status : [ FAILED ] API Workers are accessible directly!"
fi
echo "=================================================="
EOF

chmod +x /root/test_soal14.sh
/root/test_soal14.sh

#UJI MANUAL DI CLIENT EX ITADORI
curl -i http://10.80.4.11
curl -i http://10.80.4.21
#expected output HTTP/1.1 403 Forbidden

curl http://10.80.4.11
#Expected Output: <h1>Hello from Frontend Worker: maki</h1>

curl http://10.80.4.21
#Expected Output: {"status":"success","worker":"nanami","message":"Log successfully recorded to DB yaga"}

#PERBAIKI WORKER WEB MAKI & PANDA
# 1. Pastikan IP statis & default gateway terpasang
ip addr add 10.80.4.11/24 dev eth0 2>/dev/null  # (Ganti 10.80.4.12 untuk panda)
ip link set eth0 up
ip route add default via 10.80.4.1 dev eth0 2>/dev/null

# 2. Buat folder dan file index
mkdir -p /var/www/frontend
echo "<h1>Hello from Frontend Worker: $(hostname)</h1>" > /var/www/frontend/index.php

# 3. Buat Virtual Host Nginx
cat << 'CONFIG' > /etc/nginx/sites-available/frontend
server {
    listen 80;
    server_name _;

    root /var/www/frontend;
    index index.php index.html;

    # Hanya izinkan Gojo (10.80.1.4)
    allow 10.80.1.4;
    deny all;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
CONFIG

ln -sf /etc/nginx/sites-available/frontend /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 4. Restart service
/etc/init.d/php8.2-fpm restart 2>/dev/null || /etc/init.d/php-fpm restart 2>/dev/null
/etc/init.d/nginx restart

# 5. Cek apakah Nginx sudah LISTEN di port 80
netstat -tulpn | grep 80

#PERBAIKI WORKER WEB NANAMI, TODO, KIRARA
# 1. Pastikan IP statis & default gateway terpasang
ip addr add 10.80.4.21/24 dev eth0 2>/dev/null  # (Sesuaikan IP untuk todo: .22, kirara: .23)
ip link set eth0 up
ip route add default via 10.80.4.1 dev eth0 2>/dev/null

# 2. Buat folder dan file API
mkdir -p /var/www/api
cat << 'PHP' > /var/www/api/index.php
<?php
header('Content-Type: application/json');

$host = '10.80.4.30';
$db   = 'db_shibuya_Kel33';
$user = 'shibuya_user';
$pass = 'CHANGE_ME_SHIBUYA_PASSWORD';

$client_ip = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'];
$hostname  = gethostname();

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8", $user, $pass);
    $stmt = $pdo->prepare("INSERT INTO request_logs (client_ip, message) VALUES (?, ?)");
    $stmt->execute([$client_ip, "API Request processed by worker: $hostname"]);

    echo json_encode([
        "status" => "success",
        "worker" => $hostname,
        "message" => "Log successfully recorded to DB yaga"
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
PHP

# 3. Buat Virtual Host Nginx
cat << 'CONFIG' > /etc/nginx/sites-available/api
server {
    listen 80;
    server_name _;

    root /var/www/api;
    index index.php;

    # Hanya izinkan Geto (10.80.4.20)
    allow 10.80.4.20;
    deny all;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
CONFIG

ln -sf /etc/nginx/sites-available/api /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 4. Restart service
/etc/init.d/php8.2-fpm restart 2>/dev/null || /etc/init.d/php-fpm restart 2>/dev/null
/etc/init.d/nginx restart

# 5. Cek port 80
netstat -tulpn | grep 80

#PASTIKAN LISTEN

#PERBAIKAN UNTUK PANDA
# Hapus IP maki yang terpasang salah dan ganti dengan IP panda (10.80.4.12)
ip addr del 10.80.4.11/24 dev eth0 2>/dev/null
ip addr add 10.80.4.12/24 dev eth0 2>/dev/null
ip link set eth0 up
ip route add default via 10.80.4.1 dev eth0 2>/dev/null

# Tulis vhost lengkap
cat << 'CONFIG' > /etc/nginx/sites-available/frontend
server {
    listen 80;
    server_name _;

    root /var/www/frontend;
    index index.php index.html;

    allow 10.80.1.4;
    deny all;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
CONFIG

/etc/init.d/nginx restart

#PERBAIKAN UNTUK TODO
# Set IP todo (10.80.4.22)
ip addr del 10.80.4.21/24 dev eth0 2>/dev/null
ip addr add 10.80.4.22/24 dev eth0 2>/dev/null
ip link set eth0 up
ip route add default via 10.80.4.1 dev eth0 2>/dev/null

# Tulis vhost lengkap
cat << 'CONFIG' > /etc/nginx/sites-available/api
server {
    listen 80;
    server_name _;

    root /var/www/api;
    index index.php;

    allow 10.80.4.20;
    deny all;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
CONFIG

ln -sf /etc/nginx/sites-available/api /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
/etc/init.d/nginx restart

#PERBAIKAN UNTUK KIRARA
# Set IP kirara (10.80.4.23)
ip addr del 10.80.4.21/24 dev eth0 2>/dev/null
ip addr add 10.80.4.23/24 dev eth0 2>/dev/null
ip link set eth0 up
ip route add default via 10.80.4.1 dev eth0 2>/dev/null

# Tulis vhost lengkap
cat << 'CONFIG' > /etc/nginx/sites-available/api
server {
    listen 80;
    server_name _;

    root /var/www/api;
    index index.php;

    allow 10.80.4.20;
    deny all;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
CONFIG

ln -sf /etc/nginx/sites-available/api /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
/etc/init.d/nginx restart

#TES DI ITADORI
/root/test_soal14.sh
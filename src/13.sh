#YAGA
cat << 'EOF' > /root/setup.sh
#!/bin/sh

# 1. Set IP dan Gateway
ip addr del 10.80.4.9/24 dev eth0 2>/dev/null
ip addr add 10.80.4.30/24 dev eth0 2>/dev/null
ip link set eth0 up
ip route add default via 10.80.4.1 dev eth0 2>/dev/null

while ! ping -c 1 -W 1 10.80.4.1 >/dev/null 2>&1; do sleep 1; done

# 2. Install MariaDB Server jika belum ada
if ! which mariadb >/dev/null 2>&1; then
    rm -rf /etc/apt/sources.list.d/*
    echo "deb [trusted=yes check-valid-until=no] http://deb.debian.org/debian trixie main" > /etc/apt/sources.list
    apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false
    apt-get install -y --allow-unauthenticated mariadb-server mariadb-client
fi

# 3. Buat folder log & atur permissions
mkdir -p /var/log/mysql
chown -R mysql:mysql /var/log/mysql
chmod 755 /var/log/mysql

# 4. Konfigurasi MariaDB Master
cat << 'CONFIG' > /etc/mysql/mariadb.conf.d/50-server.cnf
[mysqld]
user                    = mysql
pid-file                = /run/mysqld/mysqld.pid
basedir                 = /usr
datadir                 = /var/lib/mysql
tmpdir                  = /tmp
lc-messages-dir         = /usr/share/mysql
bind-address            = 0.0.0.0
server-id               = 1
log_bin                 = /var/log/mysql/mysql-bin.log
expire_logs_days        = 10
max_binlog_size         = 100M
CONFIG

# 5. Restart & Reset Master Log
/etc/init.d/mariadb restart 2>/dev/null || service mariadb restart 2>/dev/null
while ! mariadb -u root -e "SELECT 1;" >/dev/null 2>&1; do sleep 1; done

mariadb -u root << 'SQL'
CREATE DATABASE IF NOT EXISTS db_shibuya_Kel33;

USE db_shibuya_Kel33;
CREATE TABLE IF NOT EXISTS request_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_ip VARCHAR(45),
    message VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bersihkan data lama jika ada
TRUNCATE TABLE request_logs;

CREATE USER IF NOT EXISTS 'replica_user'@'%' IDENTIFIED BY 'CHANGE_ME_REPLICA_PASSWORD';
GRANT REPLICATION SLAVE ON *.* TO 'replica_user'@'%';

CREATE USER IF NOT EXISTS 'shibuya_user'@'10.80.4.%' IDENTIFIED BY 'CHANGE_ME_SHIBUYA_PASSWORD';
GRANT ALL PRIVILEGES ON db_shibuya_Kel33.* TO 'shibuya_user'@'10.80.4.%';

FLUSH PRIVILEGES;
RESET MASTER;
SQL

echo "[SUCCESS] MariaDB Master (yaga) Berhasil Dikonfigurasi!"
EOF

chmod +x /root/setup.sh
/root/setup.sh

#INUMAKI
cat << 'EOF' > /root/setup.sh
#!/bin/sh

while ! ping -c 1 -W 1 10.80.4.1 >/dev/null 2>&1; do sleep 1; done

# 1. Install MariaDB jika belum ada
if ! which mariadb >/dev/null 2>&1; then
    rm -rf /etc/apt/sources.list.d/*
    echo "deb [trusted=yes check-valid-until=no] http://deb.debian.org/debian trixie main" > /etc/apt/sources.list
    apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false
    apt-get install -y --allow-unauthenticated mariadb-server mariadb-client
fi

# 2. Konfigurasi MariaDB Slave
cat << 'CONFIG' > /etc/mysql/mariadb.conf.d/50-server.cnf
[mysqld]
user                    = mysql
pid-file                = /run/mysqld/mysqld.pid
basedir                 = /usr
datadir                 = /var/lib/mysql
tmpdir                  = /tmp
lc-messages-dir         = /usr/share/mysql
bind-address            = 0.0.0.0
server-id               = 2
read_only               = ON
CONFIG

/etc/init.d/mariadb restart 2>/dev/null || service mariadb restart 2>/dev/null

# 3. Tunggu sampai yaga (10.80.4.30) bisa diakses
while ! mariadb -h 10.80.4.30 -u replica_user -pCHANGE_ME_REPLICA_PASSWORD -e "SELECT 1;" >/dev/null 2>&1; do
    sleep 1
done

# 4. Ambil posisi log terbaru dari yaga
LOG_FILE=$(mariadb -h 10.80.4.30 -u replica_user -pCHANGE_ME_REPLICA_PASSWORD -e "SHOW MASTER STATUS\G" 2>/dev/null | grep -i "File:" | awk '{print $2}')
LOG_POS=$(mariadb -h 10.80.4.30 -u replica_user -pCHANGE_ME_REPLICA_PASSWORD -e "SHOW MASTER STATUS\G" 2>/dev/null | grep -i "Position:" | awk '{print $2}')

LOG_FILE=${LOG_FILE:-"mysql-bin.000001"}
LOG_POS=${LOG_POS:-320}

# 5. Hubungkan Slave ke Master
mariadb -u root << SQL
STOP SLAVE;
RESET SLAVE;
CREATE DATABASE IF NOT EXISTS db_shibuya_Kel33;
USE db_shibuya_Kel33;
CREATE TABLE IF NOT EXISTS request_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_ip VARCHAR(45),
    message VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
TRUNCATE TABLE request_logs;

CHANGE MASTER TO
  MASTER_HOST='10.80.4.30',
  MASTER_USER='replica_user',
  MASTER_PASSWORD='CHANGE_ME_REPLICA_PASSWORD',
  MASTER_LOG_FILE='$LOG_FILE',
  MASTER_LOG_POS=$LOG_POS;
START SLAVE;
SQL

echo "[SUCCESS] MariaDB Slave (inumaki) Berhasil Dikonfigurasi!"
EOF

chmod +x /root/setup.sh
/root/setup.sh

#CEK DI INUMAKI
cat << 'EOF' > /root/test_soal13.sh
#!/bin/sh

MASTER_IP="10.80.4.30"
DB_NAME="db_shibuya_Kel33"

echo "=================================================="
echo "    PEMBUKTIAN REPLIKASI MARIADB (SOAL NO 13)     "
echo "=================================================="
echo ""

# 1. Cek Status Replikasi di inumaki
echo "[1] Memeriksa Status Replikasi di inumaki..."
IO_STATUS=$(mariadb -u root -e "SHOW SLAVE STATUS\G" 2>/dev/null | grep "Slave_IO_Running:" | awk '{print $2}')
SQL_STATUS=$(mariadb -u root -e "SHOW SLAVE STATUS\G" 2>/dev/null | grep "Slave_SQL_Running:" | awk '{print $2}')

echo "    Slave_IO_Running  : $IO_STATUS"
echo "    Slave_SQL_Running : $SQL_STATUS"

if [ "$IO_STATUS" = "Yes" ] && [ "$SQL_STATUS" = "Yes" ]; then
    echo "    Status            : [ OK ] Thread Replikasi Aktif!"
else
    echo "    Status            : [ FAILED ] Thread Replikasi Tidak Aktif!"
    echo "    Petunjuk          : Cek error dengan 'mariadb -u root -e \"SHOW SLAVE STATUS\\G\" | grep Last_.*_Error'"
    exit 1
fi
echo ""

# 2. Insert Data Baru di Master (yaga)
TEST_MSG="Aktivitas Kutukan Terdeteksi $(date '+%H:%M:%S')"
echo "[2] Memasukkan Data Log Baru pada Master yaga ($MASTER_IP)..."
echo "    Message Inserted : '$TEST_MSG'"

mariadb -h $MASTER_IP -D $DB_NAME -u shibuya_user -pCHANGE_ME_SHIBUYA_PASSWORD -e "INSERT INTO request_logs (client_ip, message) VALUES ('10.80.4.31', '$TEST_MSG');" 2>/dev/null
sleep 2
echo ""

# 3. Verifikasi Keberadaan Data di Slave (inumaki)
echo "[3] Memeriksa Sinkronisasi Data pada Slave (inumaki)..."
RESULT=$(mariadb -u root -D $DB_NAME -e "SELECT message FROM request_logs WHERE message='$TEST_MSG';" 2>/dev/null | grep "$TEST_MSG")

if [ -n "$RESULT" ]; then
    echo "    Data Found       : '$RESULT'"
    echo "    Status           : [ SUCCESS ] Replikasi Real-time Berhasil!"
else
    echo "    Status           : [ FAILED ] Data Tidak Ditemukan di Slave!"
fi
echo "=================================================="
EOF

chmod +x /root/test_soal13.sh
/root/test_soal13.sh

#KALAU MUNCUL NO, YES LAKUKAN INI DI YAGA
mariadb -u root -e "RESET MASTER;"
mariadb -u root -e "SHOW MASTER STATUS\G"
#cek master log di yaga no nya berapa

#KUNCI REPLIKASI DI INUMAKI
mariadb -u root << 'SQL'
STOP SLAVE;
RESET SLAVE;
CHANGE MASTER TO
  MASTER_HOST='10.80.4.30',
  MASTER_USER='replica_user',
  MASTER_PASSWORD='CHANGE_ME_REPLICA_PASSWORD',
  MASTER_LOG_FILE='mysql-bin.000001',
  MASTER_LOG_POS=328;
START SLAVE;
SQL

mariadb -u root -e "SHOW SLAVE STATUS\G" | grep -E "Slave_.*_Running"
#pastikan kedua outputnya YES

/root/test_soal13.sh
# Cek dulu MAC si kugisaki
ip link show eth0
# Hasilnya:
69516: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN mode DEFAULT group default qlen 1000
    link/ether 02:42:53:d1:7b:00 brd ff:ff:ff:ff:ff:ff
# MAC Address: 02:42:53:d1:7b:00

# Tambahan sebelum line CONFIG di tengen
host kugisaki {
    hardware ethernet 02:42:53:d1:7b:00;
    fixed-address 10.80.3.99;
}

# Validasi konfigurasi server sebelum daemon dijalankan ulang
dhcpd -t -cf /etc/dhcp/dhcpd.conf && dhcpd -q -4 -cf /etc/dhcp/dhcpd.conf eth0

# Conf di kugisaki
auto eth0
iface eth0 inet manual
    up ip link set eth0 up
    up /bin/sh /root/setup.sh

# Isi file setup.sh kugisaki
cat << 'EOF' > /root/setup.sh
#!/bin/sh
nohup sh -c 'while ! ip -4 addr show eth0 | grep -q "inet 10.80.3.99"; do udhcpc -i eth0 -n -s /usr/share/udhcpc/default.script; sleep 2; done' >/dev/null 2>&1 &
EOF
chmod +x /root/setup.sh

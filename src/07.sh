# Update /root/setup.sh Server tengen
option domain-name-servers 10.80.1.2, 10.80.1.3;
option domain-search "Kel33.com";

subnet 10.80.2.0 netmask 255.255.255.0 {
    option routers 10.80.2.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.80.2.255;
    pool {
        allow members of "dev-team";
        range 10.80.2.10 10.80.2.35;
    }
    pool {
        allow members of "support-team";
        range 10.80.2.70 10.80.2.95;
    }
}

subnet 10.80.3.0 netmask 255.255.255.0 {
    option routers 10.80.3.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.80.3.255;
    pool {
        allow members of "short-lease";
        range 10.80.3.10 10.80.3.89;
    }
    pool {
        allow members of "long-lease";
        range 10.80.3.100 10.80.3.199;
    }
}

# Skrip pada file setup Klien Divisi A (itadori, fushiguro, zenin, okkotsu) karena sempet konflik gara-gara setup nomor sebelumnya
cat << 'EOF' > /root/setup.sh
#!/bin/sh
killall udhcpc 2>/dev/null
ip addr flush dev eth0
cat << 'SCRIPT' > /tmp/udhcpc.sh
#!/bin/sh
[ "$1" = "bound" ] || [ "$1" = "renew" ] || exit 0
ip addr add $ip/${mask:-24} broadcast ${broadcast:-10.80.2.255} dev $interface
[ -n "$router" ] && ip route add default via $router dev $interface 2>/dev/null
echo -e "nameserver 10.80.1.2\nnameserver 10.80.1.3\nsearch Kel33.com" > /etc/resolv.conf
SCRIPT
chmod +x /tmp/udhcpc.sh
nohup sh -c 'while ! ip -4 addr show eth0 | grep -q "inet 10.80.2."; do udhcpc -i eth0 -x (Isi bagian ini disesuaiin ama Hexa masing-masing) -n -s /tmp/udhcpc.sh; sleep 2; done' >/dev/null 2>&1 &
EOF
chmod +x /root/setup.sh

# Test klien manapun pakek
ip addr show eth0
# Nunjukin satu IPv4
ip route show
# Nunjukin default route
cat /etc/resolv.conf
# Nunjukin 3 line yang sama di tiap klien
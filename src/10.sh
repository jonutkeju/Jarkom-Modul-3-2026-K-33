# Update pada Network Config jichi (/etc/network/interfaces)
auto eth0
iface eth0 inet dhcp
    up /root/setup.sh

# Skrip pada file setup jichi (/root/setup.sh)
cat << 'EOF' > /root/setup.sh
#!/bin/sh
sysctl -w net.ipv4.ip_forward=1 >/dev/null
iptables -P FORWARD ACCEPT
iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

if ! which dhcrelay >/dev/null 2>&1; then
    rm -rf /etc/apt/sources.list.d/*
    echo "deb [trusted=yes check-valid-until=no] http://deb.debian.org/debian trixie main" > /etc/apt/sources.list
    apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false
    apt-get install -y --allow-unauthenticated isc-dhcp-relay
fi

while ! ping -c 1 -W 1 10.80.4.10 >/dev/null 2>&1; do sleep 1; done
pkill dhcrelay 2>/dev/null || true
/usr/sbin/dhcrelay -4 -i eth2 -i eth3 -i eth4 10.80.4.10
EOF
chmod +x /root/setup.sh

# Update pada Network Config tengen (/etc/network/interfaces)
auto eth0
iface eth0 inet static
    address 10.80.4.10
    netmask 255.255.255.0
    gateway 10.80.4.1
    up /root/setup.sh

# tengen
ps aux | grep dhcpd
cat /var/lib/dhcp/dhcpd.leases

# jichi
ps aux | grep dhcrelay

#itadori
ip -br a show eth0
ip route show
ping -c 2 10.80.2.1

#ino
ip -br a show eth0
ip route show
ping -c 2 10.80.3.1

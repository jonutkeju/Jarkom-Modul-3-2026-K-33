# Conf di Router jichi
auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 10.80.1.1
    netmask 255.255.255.0

auto eth2
iface eth2 inet static
    address 10.80.2.1
    netmask 255.255.255.0

auto eth3
iface eth3 inet static
    address 10.80.3.1
    netmask 255.255.255.0

auto eth4
iface eth4 inet static
    address 10.80.4.1
    netmask 255.255.255.0

    up sysctl -w net.ipv4.ip_forward=1
    up iptables -P FORWARD ACCEPT
    up iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Conf Host Statis dan Data Center (utahime, shoko, gojo, tengen, geto, maki, panda, nanami, todo, kirara, yaga, inumaki)
auto eth0
iface eth0 inet static
    address 10.80.x.x
    netmask 255.255.255.0
    gateway 10.80.x.1
    up rm -f /etc/resolv.conf && echo "nameserver 192.168.122.1" > /etc/resolv.conf

# Conf Klien (itadori, fushiguro, zenin, okkotsu, ino, kusakabe, miwa, kugisaki)
auto eth0
iface eth0 inet dhcp

# Test di jichi
cat /proc/sys/net/ipv4/ip_forward
# 1
iptables -t nat -L POSTROUTING -n -v
# Ada MASQUERADE 

# Test di Node
ping -c 3 10.80.1.1
# Gaada paket loss

# Test di Klien Statis
ping -c 3 192.168.122.1
# Juga gaada paket loss
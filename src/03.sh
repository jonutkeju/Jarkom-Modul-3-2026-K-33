# Conf di Router jichi
    up echo "isc-dhcp-relay isc-dhcp-relay/servers string 10.80.4.10" | debconf-set-selections 2>/dev/null
    up echo "isc-dhcp-relay isc-dhcp-relay/interfaces string eth2 eth3 eth4" | debconf-set-selections 2>/dev/null
    up echo "isc-dhcp-relay isc-dhcp-relay/options string " | debconf-set-selections 2>/dev/null

    up which dhcrelay || (apt-get update && apt-get install -y isc-dhcp-relay)
    up echo 'SERVERS="10.80.4.10"' > /etc/default/isc-dhcp-relay
    up echo 'INTERFACES="eth2 eth3 eth4"' >> /etc/default/isc-dhcp-relay
    up echo 'OPTIONS=""' >> /etc/default/isc-dhcp-relay
    up /etc/init.d/isc-dhcp-relay restart 2>/dev/null

# Conf di seluruh Klien (itadori, fushiguro, zenin, okkotsu, ino, kusakabe, miwa, kugisaki)
    up sh -c 'while ! ip -4 addr show eth0 | grep -q "inet "; do udhcpc -i eth0 -n -q -t 5; sleep 2; done &'

# Test di Jichi
ps aux | grep dhcrelay
# Ada path file + Isinya

# Di salah satu klien masing-masing Divisi
ip a show eth0
# Suffix 2.x/24 di A, 3.x di B
ping -c 3 10.80.2.1
# Gaada paket loss

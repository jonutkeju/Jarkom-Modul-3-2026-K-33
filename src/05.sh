# Update config tengen
auto eth0
iface eth0 inet static
    address 10.80.4.10
    netmask 255.255.255.0
    gateway 10.80.4.1
    up hostname tengen
    up echo "tengen" > /etc/hostname
    up rm -f /etc/resolv.conf && echo "nameserver 192.168.122.1" > /etc/resolv.conf

    # Setupnya sekarang lewat file shell di root karna gampang banget rusak kemaren
    up /bin/sh /root/setup.sh

# Skrip pada file setup tengen (/root/setup.sh)
#!/bin/sh
while ! ping -c 1 -W 1 10.80.4.1 >/dev/null 2>&1; do sleep 1; done
if ! which dhcpd >/dev/null 2>&1; then
    rm -rf /etc/apt/sources.list.d/*
    echo "deb [trusted=yes check-valid-until=no] http://deb.debian.org/debian trixie main" > /etc/apt/sources.list
    apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false
    apt-get install -y --allow-unauthenticated isc-dhcp-server
fi

echo 'INTERFACESv4="eth0"' > /etc/default/isc-dhcp-server
echo 'INTERFACESv6=""' >> /etc/default/isc-dhcp-server

cat << 'CONFIG' > /etc/dhcp/dhcpd.conf
ddns-update-style none;
authoritative;
default-lease-time 600;
max-lease-time 7200;

subnet 10.80.4.0 netmask 255.255.255.0 {}

class "dev-team" {
    match if (substring(option dhcp-client-identifier, 0, 7) = "itadori" or substring(option dhcp-client-identifier, 1, 7) = "itadori" or option dhcp-client-identifier = "itadori" or substring(option dhcp-client-identifier, 0, 9) = "fushiguro" or substring(option dhcp-client-identifier, 1, 9) = "fushiguro" or option dhcp-client-identifier = "fushiguro");
}
class "support-team" {
    match if (substring(option dhcp-client-identifier, 0, 5) = "zenin" or substring(option dhcp-client-identifier, 1, 5) = "zenin" or option dhcp-client-identifier = "zenin" or substring(option dhcp-client-identifier, 0, 7) = "okkotsu" or substring(option dhcp-client-identifier, 1, 7) = "okkotsu" or option dhcp-client-identifier = "okkotsu");
}
subnet 10.80.2.0 netmask 255.255.255.0 {
    option routers 10.80.2.1;
    option subnet-mask 255.255.255.0;
    option domain-name-servers 192.168.122.1;
    pool {
        allow members of "dev-team";
        range 10.80.2.10 10.80.2.35;
    }
    pool {
        allow members of "support-team";
        range 10.80.2.70 10.80.2.95;
    }
}

# Soal 5
class "short-lease" {
    match if (substring(option dhcp-client-identifier, 0, 3) = "ino" or substring(option dhcp-client-identifier, 1, 3) = "ino" or option dhcp-client-identifier = "ino" or substring(option dhcp-client-identifier, 0, 8) = "kusakabe" or substring(option dhcp-client-identifier, 1, 8) = "kusakabe" or option dhcp-client-identifier = "kusakabe");
    default-lease-time 1800;
    max-lease-time 1800;
}
class "long-lease" {
    match if (substring(option dhcp-client-identifier, 0, 4) = "miwa" or substring(option dhcp-client-identifier, 1, 4) = "miwa" or option dhcp-client-identifier = "miwa");
    default-lease-time 43200;
    max-lease-time 43200;
}
subnet 10.80.3.0 netmask 255.255.255.0 {
    option routers 10.80.3.1;
    option subnet-mask 255.255.255.0;
    option domain-name-servers 10.80.1.2, 10.80.1.3;
    option domain-search "Kel33.com";
    pool {
        allow members of "short-lease";
        range 10.80.3.10 10.80.3.89;
    }
    pool {
        allow members of "long-lease";
        range 10.80.3.100 10.80.3.199;
    }
}
# Soal 5
CONFIG

mkdir -p /var/lib/dhcp /run /var/run
touch /var/lib/dhcp/dhcpd.leases
rm -f /var/run/dhcpd.pid /run/dhcpd.pid
killall dhcpd 2>/dev/null || true
dhcpd -q -4 -cf /etc/dhcp/dhcpd.conf eth0

# Conf di ino
auto eth0
iface eth0 inet manual
    up ip link set eth0 up
    up nohup sh -c 'while ! ip -4 addr show eth0 | grep -q "inet 10.80.3."; do udhcpc -i eth0 -x 61:696e6f -n -s /usr/share/udhcpc/default.script; sleep 2; done' >/dev/null 2>&1 &

# Conf di kusakabe
auto eth0
iface eth0 inet manual
    up ip link set eth0 up
    up nohup sh -c 'while ! ip -4 addr show eth0 | grep -q "inet 10.80.3."; do udhcpc -i eth0 -x 61:6b7573616b616265 -n -s /usr/share/udhcpc/default.script; sleep 2; done' >/dev/null 2>&1 &

# Conf di miwa
auto eth0
iface eth0 inet manual
    up ip link set eth0 up
    up nohup sh -c 'while ! ip -4 addr show eth0 | grep -q "inet 10.80.3."; do udhcpc -i eth0 -x 61:6d697761 -n -s /usr/share/udhcpc/default.script; sleep 2; done' >/dev/null 2>&1 &

# Test di ino, kusakabe, miya
ip -br a show eth0
# Harusnya ada IPv4nya
cat /etc/resolv.conf
# Kehubung ke internet berarti donee
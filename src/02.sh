# Conf di node tengen
    up which dhcpd || (apt-get update && apt-get install -y isc-dhcp-server)
    up echo 'INTERFACESv4="eth0"' > /etc/default/isc-dhcp-server
    up echo 'INTERFACESv6=""' >> /etc/default/isc-dhcp-server
    up echo 'default-lease-time 600;' > /etc/dhcp/dhcpd.conf
    up echo 'max-lease-time 7200;' >> /etc/dhcp/dhcpd.conf
    up echo 'ddns-update-style none;' >> /etc/dhcp/dhcpd.conf
    up echo 'authoritative;' >> /etc/dhcp/dhcpd.conf
    up echo '' >> /etc/dhcp/dhcpd.conf
    up echo 'subnet 10.80.4.0 netmask 255.255.255.0 {' >> /etc/dhcp/dhcpd.conf
    up echo '}' >> /etc/dhcp/dhcpd.conf
    up echo '' >> /etc/dhcp/dhcpd.conf
    up echo 'subnet 10.80.2.0 netmask 255.255.255.0 {' >> /etc/dhcp/dhcpd.conf
    up echo '    option routers 10.80.2.1;' >> /etc/dhcp/dhcpd.conf
    up echo '    option subnet-mask 255.255.255.0;' >> /etc/dhcp/dhcpd.conf
    up echo '    option domain-name-servers 192.168.122.1;' >> /etc/dhcp/dhcpd.conf
    up echo '}' >> /etc/dhcp/dhcpd.conf
    up echo '' >> /etc/dhcp/dhcpd.conf
    up echo 'subnet 10.80.3.0 netmask 255.255.255.0 {' >> /etc/dhcp/dhcpd.conf
    up echo '    option routers 10.80.3.1;' >> /etc/dhcp/dhcpd.conf
    up echo '    option subnet-mask 255.255.255.0;' >> /etc/dhcp/dhcpd.conf
    up echo '    option domain-name-servers 192.168.122.1;' >> /etc/dhcp/dhcpd.conf
    up echo '}' >> /etc/dhcp/dhcpd.conf
    up /etc/init.d/isc-dhcp-server restart 2>/dev/null

# Test di Tekken
dhcpd -t -cf /etc/dhcp/dhcpd.conf
# Intinya ra error wis aman lekk
/etc/init.d/isc-dhcp-server status
# Harusnya aktif, HARUSNYA
netstat -ulpn | grep dhcpd
# Ada SIX SEVENNN status listening
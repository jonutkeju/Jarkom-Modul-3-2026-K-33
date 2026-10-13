# Conf di tengen (Disisipin sebelum line deklarasi subnet mask)
    up echo 'class "dev-team" {' >> /etc/dhcp/dhcpd.conf
    up echo '    match if (option dhcp-client-identifier = "itadori" or option dhcp-client-identifier = "fushiguro");' >> /etc/dhcp/dhcpd.conf
    up echo '}' >> /etc/dhcp/dhcpd.conf
    up echo '' >> /etc/dhcp/dhcpd.conf
    up echo 'class "support-team" {' >> /etc/dhcp/dhcpd.conf
    up echo '    match if (option dhcp-client-identifier = "zenin" or option dhcp-client-identifier = "okkotsu");' >> /etc/dhcp/dhcpd.conf
    up echo '}' >> /etc/dhcp/dhcpd.conf

# Conf di tengen (Disisipin di dalam Subnet 10.80.2.0)
    up echo '    pool {' >> /etc/dhcp/dhcpd.conf
    up echo '        allow members of "dev-team";' >> /etc/dhcp/dhcpd.conf
    up echo '        range 10.80.2.10 10.80.2.35;' >> /etc/dhcp/dhcpd.conf
    up echo '    }' >> /etc/dhcp/dhcpd.conf
    up echo '    pool {' >> /etc/dhcp/dhcpd.conf
    up echo '        allow members of "support-team";' >> /etc/dhcp/dhcpd.conf
    up echo '        range 10.80.2.70 10.80.2.95;' >> /etc/dhcp/dhcpd.conf
    up echo '    }' >> /etc/dhcp/dhcpd.conf

# Conf di Node itadori, update line soal 3
    up nohup sh -c 'while ! ip -4 addr show eth0 | grep -q "inet "; do udhcpc -i eth0 -x 61:697461646f7269 -n -t 5 -T 2; sleep 3; done' >/dev/null 2>&1 &

# Conf di Node fushiguro, update line soal 3
    up nohup sh -c 'while ! ip -4 addr show eth0 | grep -q "inet "; do udhcpc -i eth0 -x 61:66757368696775726f -n -t 5 -T 2; sleep 3; done' >/dev/null 2>&1 &

# Conf di Node zenin, update line soal 3
    up nohup sh -c 'while ! ip -4 addr show eth0 | grep -q "inet "; do udhcpc -i eth0 -x 61:7a656e696e -n -t 5 -T 2; sleep 3; done' >/dev/null 2>&1 &

# Conf di Node okkotsu, update line soal 3
    up nohup sh -c 'while ! ip -4 addr show eth0 | grep -q "inet "; do udhcpc -i eth0 -x 61:6f6b6b6f747375 -n -t 5 -T 2; sleep 3; done' >/dev/null 2>&1 &

# Cek di Klien Pool 1 dan 2
ip a show eth0
# Pool 1 harusnya dapet antara 10.80.2.10–10.80.2.35
# Pool 2 harusnya dapet antara 10.80.2.70–10.80.2.95

# Cek di tengen
grep -E "lease 10\.80\.2\." /var/lib/dhcp/dhcpd.leases
# Kalo keluar at least 2 IP dari masing-masing pool dan gaada yang diluar itu, Amann
# Cons di tengen
tcpdump -i eth0 -nv -s 0 port 67 or port 68

# Cons salah satu klien
killall udhcpc 2>/dev/null
ip addr flush dev eth0
udhcpc -i eth0 -x 61:696e6f -n -q -s /usr/share/udhcpc/default.script

# Setelah udhpc jalan, harusnya muncul pesan berhasil di klien
# Dan beberapa paket DHCP (4) di tengen
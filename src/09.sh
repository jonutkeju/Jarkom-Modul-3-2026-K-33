# Cons di jichi
pkill dhcrelay
ps aux | grep dhcrelay

# Cons di salah satu klien
killall udhcpc 2>/dev/null
ip addr flush dev eth0

# Cons di jichi, idupin dhcrelaynya
/usr/sbin/dhcrelay -4 -i eth2 -i eth3 -i eth4 10.80.4.10

# Ke klien lagi
udhcpc -i eth0 -x (Sesuaiin Hexanya) -n -t 3 -s /usr/share/udhcpc/default.script
ip -br a show eth0
ip route show

# Kalo bisa berarti amann
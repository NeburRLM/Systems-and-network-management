#!/bin/bash

# Configuració del servei zebra
touch /etc/quagga/zebra.conf

# Configuració de mascarada en R1 (només si el hostname és router1)
if [ "$(hostname)" == "router1" ]; then
    # Configuració del servei ripd
    cat <<EOF > /etc/quagga/ripd.conf
router rip
   version 2
   network 10.192.1.1/30
   network 10.192.4.2/30
   default-information originate
   passive-interface eth0
EOF

    apt-get update
    apt-get install -y iptables

    echo 1 > /proc/sys/net/ipv4/ip_forward
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
else
    router_number=$(hostname | grep -o '[0-9]\+')
    prev_router_number=$((router_number - 1))
    # Configuració del servei ripd
    cat <<EOF > /etc/quagga/ripd.conf
router rip
    version 2
    network 10.192.${prev_router_number}.2/30
    network 10.192.${router_number}.1/30
EOF

fi

# Ajustar permissos
chown -R quagga.quaggavty /etc/quagga/
chmod 640 /etc/quagga/*.conf

service zebra restart
service ripd restart

#!/bin/bash

# Configurar la interfície eth0 estàticament
if ! grep -q "iface eth0 inet static" /etc/network/interfaces; then
    sed -i 's/iface eth0 inet dhcp/iface eth0 inet static/g' /etc/network/interfaces
    echo "
    address 172.24.255.254
    netmask 255.255.192.0
    network 172.24.192.0
    broadcast 172.24.255.255
    gateway 172.24.192.1
    " >> /etc/network/interfaces
    ifdown eth0 && ifup eth0
fi

# Temporalment, configurar /etc/resolv.conf amb la IP del router en la Intranet
if [[ ! $(cat /etc/resolv.conf | grep "nameserver 172.24.192.1") ]] ; then
	echo "nameserver 172.24.192.1" >> /etc/resolv.conf  
fi


# Comprovar si el paquete isc-dhcp-server està instal·lat i si no, instal·lar-lo
if ! dpkg -s isc-dhcp-server &> /dev/null; then
    echo "El paquet isc-dhcp-server no està instal·lat, instal·lant..."
    apt update
    apt install -y isc-dhcp-server
fi

# Configurar isc-dhcp-server per a que escolti en eth0
if grep -q "INTERFACESv4=\"eth0\"" /etc/default/isc-dhcp-server; then
    echo "La configuració ya es troba en /etc/default/isc-dhcp-server."
else
    sed -i 's/INTERFACESv4=""/INTERFACESv4="eth0"/g' /etc/default/isc-dhcp-server
    echo "Configuració agregada a /etc/default/isc-dhcp-server."
fi


# Configurar el arxiu /etc/dhcp/dhcpd.conf
cat <<EOF > /etc/dhcp/dhcpd.conf
subnet 172.24.192.0 netmask 255.255.192.0 {
    range 172.24.192.2 172.24.255.253;
    option subnet-mask 255.255.192.0;
    option broadcast-address 172.24.255.255;
    option routers 172.24.192.1;
    default-lease-time 7200; # 2 hores
    max-lease-time 28800;    # 8 hores
    option domain-name-servers 198.18.207.254;
    option domain-name "intranet.gsx";
    option domain-search "intranet.gsx","dmz.gsx";
}
EOF

# Reiniciar el servei DHCP
systemctl restart isc-dhcp-server

echo "Configuració completada."
